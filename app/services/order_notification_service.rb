class OrderNotificationService
  VENDOR_SMS_NOTIFICATIONS = %i[new_order paid canceled run_out].freeze

  attr_reader :order

  def initialize(order)
    raise 'order must be a persisted Order' unless order.is_a?(Order) && order.persisted?

    @order = order
  end

  def new_order
    log 'notification new_order'
    notify_client :new_order
    notify_vendor :new_order
  end

  def workflow_changed(workflow_was:)
    log "notification workflow_changed, workflow_was=#{workflow_was}"
    notify_client :workflow_changed, workflow_was: workflow_was
    notify_vendor :workflow_changed, workflow_was: workflow_was
  end

  def payment_link
    log 'payment_link'
    notify_client :payment_link
  end

  def order_paid
    log 'order_paid'
    notify_client :paid
    notify_vendor :paid
  end

  def canceled_order_paid
    log 'canceled_order_paid'
    notify_vendor :paid_cancelled
  end

  def order_has_run_out_goods
    log 'order_has_run_out_goods'
    notify_vendor :run_out
  end

  def delivery_expired
    log 'order_delivery_expired'
    notify_client :delivery_expired
  end

  def notify_by_template(template)
    namespace, key = template.split(':').map(&:to_sym)
    case namespace
    when :client
      notify_client key
    when :merchant
      notify_vendor key
    else
      Bugsnag.notify "Unknown namespace #{namespace}"
    end
  end

  def notify_client(key, payload = nil)
    safe do
      send_sms_to_client key, payload if allow_sms_notification? :client, key, :sms
      send_email_to_client key, payload if allow_email_notification? :client, key, :email
    end
  end

  private

  delegate :vendor, to: :order

  def log(message)
    Rails.logger.info "vendor_id=#{vendor.id} order_id=#{order.id} #{message}"
  end

  def log_error(message)
    Rails.logger.error "vendor_id=#{vendor.id} order_id=#{order.id} #{message}"
  end

  def safe
    yield
  rescue StandardError => e
    binding.debug_error
    log_error "error #{e}"
    Bugsnag.notify e, metaData: { order_id: order.id }
  end

  def notify_vendor(key, payload = nil)
    safe do
      send_sms_to_vendor key, payload if allow_sms_notification? :merchant, key, :sms
      send_email_to_vendor key, payload if allow_email_notification? :merchant, key, :email
    end
  end

  def allow_sms_notification?(namespace, key, channel)
    allow_template_notification?(namespace, key, channel)
  end

  def allow_email_notification?(namespace, key, channel)
    allow_template_notification?(namespace, key, channel)
  end

  # TODO: переименовать mail_template потому что это не только лишь email, но и SMS
  def allow_template_notification?(namespace, key, channel)
    raise "Unknown namespace #{namespace}" unless MailTemplate::NAMESPACES.include? namespace.to_s

    mail_template = vendor.mail_templates.find_or_initialize_by key: key, namespace: namespace, locale: order.locale
    mail_template.allow_notification? channel
  end

  def send_email_to_client(meth, payload = nil)
    log "send_email_to_client method=#{meth}, payload=#{payload}"
    CustomOrderMailer.send_client_mail(meth.to_s, order.id, payload).deliver_later!
  end

  def send_email_to_vendor(meth, payload = nil)
    return if vendor.order_notification_emails_array.blank?

    log "send_email_to_vendor method=#{meth}, payload=#{payload}"
    CustomOrderMailer.send_merchant_mail(meth.to_s, order.id, payload).deliver_later!
  end

  def send_sms_to_vendor(key, payload = nil)
    log "send_sms_to_vendor key=#{key}, payload=#{payload}"
    send_sms order.vendor.order_notification_phones_array, key.to_s, 'merchant', payload
  end

  def send_sms_to_client(key, payload = nil)
    log "send_sms_to_client key=#{key}, payload=#{payload}"
    send_sms order.phone, key.to_s, 'client', payload
  end

  def send_sms(phones, key, namespace, payload = nil)
    if phones.present?
      SmsWorker.perform_async phones, sms_text(key, namespace, payload), vendor.id
    else
      log "No phones to send SMS #{key} #{namespace} #{payload}"
    end
  end

  def sms_text(key, namespace, payload = nil)
    template = vendor.mail_templates.get key: key, namespace: namespace, locale: order.locale
    context = MailContext.new order: order, client: order.client, template: template, payload: payload
    template.to_sms context
  end
end
