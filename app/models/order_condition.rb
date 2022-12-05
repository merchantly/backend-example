class OrderCondition < ApplicationRecord
  include RankedModel
  include Authority::Abilities
  include Archivable
  extend Enumerize

  ACTIONS = %i[delivery reserve unreserve change_state notification warehouse].freeze
  EVENTS = %i[on_create on_workflow_change on_pay_success on_pay_failure].freeze

  strip_attributes

  ranks :position, with_same: :vendor_id, scope: :alive

  # TODO валидировать следующие варианты:
  # 1. Когда пытаются установить workflow_state/finite_state на on_create. в этом нет смысла потому что при создании статус будет всегда один
  # 2. Когда пытаются установить и workflow_state и finite_state

  belongs_to :vendor
  belongs_to :vendor_delivery
  belongs_to :vendor_payment
  belongs_to :enter_workflow_state, class_name: 'WorkflowState'

  has_many :order_condition_orders, dependent: :destroy
  has_many :orders, through: :order_condition_orders

  scope :ordered, -> { order :id }

  class << self; remove_method :alive; end
  scope :alive, -> { all }

  scope :with_event, ->(event) { where event: event }
  scope :with_workflow_state, lambda { |workflow_state|
    where '(enter_workflow_state_id = ? or enter_workflow_state_id is null) and (enter_finite_state = ? or enter_finite_state is null)',
          workflow_state.id, workflow_state.finite_state
  }

  scope :with_vendor_delivery, lambda { |delivery|
    where 'vendor_delivery_id = ? or vendor_delivery_id is null', delivery.id
  }

  scope :with_vendor_payment, lambda { |payment|
    where 'vendor_payment_id = ? or vendor_payment_id is null', payment.id
  }

  scope :with_order_payment_state, ->(state) { where 'order_payment_state = ? or order_payment_state is null', state }
  scope :with_order_delivery_state, ->(state) { where 'order_delivery_state = ? or order_delivery_state is null', state }

  validates :enter_finite_state, inclusion: WorkflowState.finite_state.values, allow_nil: true

  enumerize :action, in: ACTIONS, predicates: true, scope: true
  enumerize :event, in: EVENTS, predicates: true

  validates :event, presence: true, inclusion: event.values
  validates :after_time_minutes, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :notification_template, presence: true, if: proc { |oc| oc.action == :notification }
  validates :to_order_workflow_state_id, presence: true, if: proc { |oc| oc.action == :change_state }

  def title
    I18n.t('order_condition.title', action_text: action_text, conditions_text: conditions_text, event_text: event_text)
  end

  def conditions_text
    [delivery_title, payment_title, enter_workflow_title, enter_finite_state_title].compact.join(' + ').presence ||
      I18n.t('order_condition.default_text')
  end

  def delivery_title
    vendor_delivery.present? ? I18n.t('order_condition.delivery_title', vendor_delivery: vendor_delivery.to_s) : nil
  end

  def payment_title
    vendor_payment.present? ? I18n.t('order_condition.payment_title', vendor_payment: vendor_payment.to_s) : nil
  end

  def enter_workflow_title
    enter_workflow_state.present? ? I18n.t('order_condition.enter_workflow_title', state: enter_workflow_state.to_s) : nil
  end

  def enter_finite_state_title
    enter_finite_state.present? ? I18n.t('order_condition.enter_finite_state_title', state: I18n.t(enter_finite_state, scope: %i[enumerize finite_state])) : nil
  end

  def mark_as_used_with_order!(order)
    order_condition_orders.create! order: order
  end

  def do_action!(order)
    # если событие вызвалось отложенно
    # то проверяем условия повторно путем попытки найти текущий condition по условиям
    return if after_time_minutes.present? && !suitable_order_condition?(order)

    mark_as_used_with_order! order
    order.log! :use_condition, title: title, id: id
    case action.to_sym
    when :delivery
      order.reserve_items_on_stock!
      order.commands.start_delivery!
    when :reserve
      order.reserve_items_on_stock!
    when :unreserve
      order.unreserve_items_on_stock!
    when :change_state
      order.update_attribute :workflow_state_id, to_order_workflow_state_id
    when :notification
      OrderNotificationService.new(order).notify_by_template(notification_template)
    else
      raise "Unknown action #{action}"
    end
  end

  private

  def suitable_order_condition?(order)
    order.possible_order_conditions.exists?(id)
  end
end
