module OrderCallbacks
  extend ActiveSupport::Concern

  DEFAULT_CONDITION_DELAY_PERIOD = 1.second

  included do
    before_save :set_address_from_parts, if: :is_separate_address
    before_save :set_name_from_parts, if: :is_separate_name
    after_commit :notify_convead
    before_save :archive_failure, if: :will_save_change_to_archived_at?
    before_save :set_delivery_time_title
    before_save :set_yandex_delivery_title
    before_save :set_cdek_delivery_title
    after_commit :send_bitrix24, on: :create
    before_save :set_past_workflow_state, if: :will_save_change_to_workflow_state_id?
    after_save :changed_workflow, if: :saved_change_to_workflow_state_id?
  end

  # Вызывается вручную из WebOrderCreator
  #
  def on_created
    Rails.logger.info "order_id=#{id} callback on_created"
    OrderNotificationService.new(self).new_order
    do_actions_for_event :on_create
  end

  def on_pay_successful
    Rails.logger.info "order_id=#{id} callback on_pay_successful"
    OrderNotificationService.new(self).order_paid unless IntegrationModules.enable?(:ecr)
    send_coupon_images
    do_actions_for_event :on_pay_success

    if IntegrationModules.enable?(:ecr)
      cashier = payment_type.cashier || vendor.default_cashier

      form = Ecr::DocumentForm::Sale.new(
        vendor: vendor,
        order_id: id,
        cashier_id: cashier.id,
        amount: total_with_delivery_price
      )

      Ecr::DocumentRegistrar.sale(form)
    end
  end

  def on_pay_failure
    Rails.logger.info "order_id=#{id} callback on_pay_failure"
    do_actions_for_event :on_pay_failure
  end

  private

  def notify_convead
    return unless vendor.use_convead?

    ConveadHookWorker.perform_async id, workflow_state.convead_key if workflow_state.convead_key.present?
  end

  def do_actions_for_event(event)
    raise "Unknown event #{event}" unless OrderCondition.event.values.include? event.to_sym

    possible_order_conditions
      .with_event(event)
      .each do |c|
        # запускаем действие отложенно если заполнено поле after_time_minutes
        if c.after_time_minutes.present?
          OrderConditionDelayWorker.perform_in(c.after_time_minutes.minutes, c.id, id)
        else
          if Rails.env.production?
            # Чтобы заказ успел выполнить все коллбеки и обновить свои атрибуты
            OrderConditionDelayWorker.perform_in(DEFAULT_CONDITION_DELAY_PERIOD, c.id, id)
          else
            c.do_action!(self)
          end
        end
      end
  end

  def set_past_workflow_state
    self.past_workflow_state_id = workflow_state_id_was
  end

  def changed_workflow
    return true if past_workflow_state.blank?

    log! :changed_workflow_state, workflow_state_from: past_workflow_state.to_s, workflow_state_to: workflow_state.to_s

    # Пока убрали такое поведение
    # on_workflow_transition from: :working?, to: :finish? do
    #   archive
    # end

    on_workflow_transition from: :working?, to: :failure? do
      cancel!
    end

    on_workflow_transition from: :finish?, to: :working? do
      restore
    end

    do_actions_for_event :on_workflow_change

    true
  end

  def cancel!
    unreserve_items_on_stock!
    order_delivery.cancel! unless order_delivery.done?
    order_payment.cancel! unless order_payment.paid?
  end

  def archive_failure
    self.workflow_state = vendor.workflow_states.failure if (new? || in_process?) && archived?
  end

  def on_workflow_transition(from:, to:)
    yield if past_workflow_state.send(from) && workflow_state.send(to)
  end

  def set_address_from_parts
    house_with_slash = slash.present? ? "#{house}-#{slash}" : house

    self.address = [street, I18n.t('activerecord.order.address.house'), house_with_slash, I18n.t('activerecord.order.address.room'), room].compact.join(' ')
  end

  def set_name_from_parts
    self.name = [second_name, first_name, patronymic].join(' ')
  end

  def set_delivery_time_title
    self.delivery_time_title = delivery_time_period.title if delivery_time_period.present?
  end

  def set_yandex_delivery_title
    self.yandex_delivery_title = yandex_delivery.title if yandex_delivery.present?
  end

  def set_cdek_delivery_title
    self.cdek_delivery_title = cdek_delivery.title if cdek_delivery.present?
  end

  def send_coupon_images
    items.find_each do |order_item|
      CouponImageMailer.send_client_mail(order_item.id).deliver if order_item.has_digital_key?
    end
  end

  def send_bitrix24
    Bitrix24OrderCreateWorker.perform_async id if vendor.vendor_bitrix24.try :is_active
  end
end
