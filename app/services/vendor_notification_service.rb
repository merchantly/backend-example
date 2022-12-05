class VendorNotificationService
  # Сколько клиента можно не уведомлять
  CLIENT_NOTIFIED_PERIOD = 1.day

  include MoneyRails::ActionViewExtension
  include MoneyHelper
  include RoutesConcern

  attr_reader :vendor

  def initialize(vendor)
    @vendor = vendor
  end

  def notify_shop_archived
    return unless vendor.allow_system_notification?

    vendor.operators.each do |operator|
      OperatorMailer.vendor_archived(operator.id, vendor.id).deliver! if operator.email.present?
    end
  end

  def analytics_notify(prev_week_orders_count, last_week_orders_count)
    return unless vendor.allow_system_notification?

    OperatorMailer.analytics_notify(vendor.basic_operator.id, vendor.id, prev_week_orders_count, last_week_orders_count) if vendor.basic_operator.present?
  end

  def partner_incoming(transaction)
    message = I18n.t('services.vendor_notifications.partner_incoming.sms_text',
                     amount: humanized_money_with_symbol(transaction.amount),
                     name: transaction.partner.name,
                     current_amount: humanized_money_with_symbol(transaction.to_account.amount),
                     details: transaction.details,
                     coupon_code: transaction.meta.coupon_code,
                     coupon_percent: Partner::Coupon.find_by(code: transaction.meta.coupon_code).reward_percent)

    SupportMailer.universal_mail(transaction.partner.email, message, subject: 'Пополнение партнерского баланса в kiiiosk.store').deliver_later! if transaction.partner.email.present?

    # SmsWorker.perform_async [transaction.partner.phone], message if transaction.partner.phone.present?
  end

  def notify_owners(mail_subject:, mail_text:, sms_text:)
    return unless vendor.allow_system_notification?

    mail_template = Liquid::Template.parse(mail_text)
    # sms_template = Liquid::Template.parse(sms_text)
    Rails.logger.debug sms_text

    vendor.owners.each do |member|
      OperatorMailer.notify_member(member.id, mail_subject, mail_template.render('member_key' => MemberAccessTokenizer.generate(member))).deliver! if member.email.present?
      # SmsWorker.perform_async(member.phone, sms_template.render('member_key' => MemberAccessTokenizer.generate(member))) if member.phone.present?
    end
  end

  def notify_shop_will_archive
    return unless vendor.allow_system_notification?

    vendor.operators.each do |operator|
      OperatorMailer.notify_shop_will_archive(operator.id, vendor.id).deliver! if operator.email.present?
    end
  end

  def system_notify(template)
    return unless vendor.allow_system_notification?

    vendor.operators.system_mail_recipients(SystemMailTemplate::TYPE_TECH).each do |operator|
      OperatorMailer.system_notify(operator.id, vendor.id, template.key).deliver! if operator.email.present?
    end
  end

  def negative_balance
    return unless vendor.allow_system_notification?

    vendor.owners.each do |member|
      OperatorMailer.negative_balance(member.id, vendor.id, humanized_money_with_symbol(vendor.common_billing_account.amount)).deliver! if member.email.present?
    end
    # SmsWorker.perform_async vendor.owner_phones_array, I18n.t('services.vendor_notifications.negative_balance.sms_text', balance: humanized_money_with_symbol(vendor.common_billing_account.amount), url: vendor.host)
  end

  # уведомление вендора о необходимости оплаты тарифа
  # для новых тарифов
  def need_payment(invoice:)
    return unless vendor.allow_system_notification?
    return unless invoice.make_notification?

    invoice.increment_notification!

    Billing.logger.info "VendorNotificationService: Уведомляю о необходимости оплаты по счету #{invoice.number} на сумму #{invoice.amount} вендора #{vendor.id}"

    vendor.owners.each do |member|
      OperatorMailer.need_payment(member.id, vendor.id, invoice.id).deliver! if member.email.present?
    end

    # SmsWorker.perform_async(
    # vendor.owner_phones_array,
    # I18n.t(
    # 'services.vendor_notifications.need_payment.sms_text',
    # url: vendor.host,
    # tariff_name: vendor.tariff.try(:title),
    # current_amount: humanized_money_with_symbol(vendor.common_billing_account.amount),
    # invoice_amount: humanized_money_with_symbol(invoice.amount),
    # unpublish_date: vendor.working_to.present? ? I18n.l(vendor.working_to.to_date) : nil,
    # payment_link: system_invoice_url(id: invoice.id)
    # )
    # )
  end

  # недостаточно баланса для отправки SMS
  def not_enough_sms_money
    return unless vendor.allow_system_notification?
    return if vendor.not_enough_sms_money_notify_date.present?

    vendor.owners.each do |member|
      OperatorMailer.delay.not_enough_sms_money(member.id, vendor.id).deliver! if member.email.present?
    end

    # SmsWorker.perform_async(
    # vendor.owner_phones_array,
    # I18n.t('services.vendor_notifications.not_enough_sms_money.sms_text', url: vendor.host)
    # )
  ensure
    vendor.touch(:not_enough_sms_money_notify_date)
  end

  # SMS баланс достиг отметки уведомления клиента об окончании средств
  def sms_money_limit_reached
    return unless vendor.allow_system_notification?

    vendor.owners.each do |member|
      OperatorMailer.sms_money_limit_reached(member.id, vendor.id).deliver! if member.email.present?
    end
    vendor.touch(:sms_money_limit_reached_notify_date)
  end

  # магазин снят с публикации
  def unpublish
    return unless vendor.allow_system_notification?

    vendor.owners.each do |member|
      OperatorMailer.unpublish(member.id, vendor.id).deliver! if member.email.present?
    end

    SmsWorker.perform_async vendor.owner_phones_array, I18n.t('services.vendor_notifications.unpublish.sms_text', url: vendor.host)
  end

  # уведомление вендора о пополнении баланса
  def balance_refill(transaction)
    return unless vendor.allow_system_notification?

    vendor.owners.each do |member|
      OperatorMailer.balance_refill(member.id, vendor.id, transaction.id) if member.email.present?
    end

    # SmsWorker.perform_async(
    # vendor.owner_phones_array,
    # I18n.t('services.vendor_notifications.balance_refill.sms_text',
    # amount: humanized_money_with_symbol(transaction.amount),
    # url: vendor.host,
    # current_amount: humanized_money_with_symbol(transaction.to_account.amount))
    # )
  end

  # уведомление вендора о списании денег
  def balance_subtract(transaction)
    return unless vendor.allow_system_notification?

    vendor.owners.each do |member|
      OperatorMailer.balance_subtract(member.id, vendor.id, transaction.id).deliver! if member.email.present?
    end

    # SmsWorker.perform_async(
    # vendor.owner_phones_array,
    # I18n.t('services.vendor_notifications.balance_subtract.sms_text',
    # amount: humanized_money_with_symbol(transaction.amount),
    # url: vendor.host,
    # current_amount: humanized_money_with_symbol(transaction.from_account.amount),
    # details: transaction.details)
    # )
  end
end
