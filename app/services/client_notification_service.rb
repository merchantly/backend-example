class ClientNotificationService
  def initialize(client)
    @client = client || raise('Client is empty')
  end

  def client_category_changed
    notify :client_category_changed
  end

  private

  attr_reader :client

  def notify(key)
    send_sms key if allow_notification? key, :sms
    send_email key if allow_notification? key, :email
  rescue StandardError => e
    Bugsnag.notify e
  end

  def allow_notification?(key, channel)
    mail_template = client.vendor.mail_templates.find_or_initialize_by key: key, namespace: :client
    mail_template.allow_notification? channel
  end

  def send_sms(key)
    if client.phone.present?
      SmsWorker.perform_async client.phone, sms_text(key), client.vendor.id
    else
      log "No phones to send SMS #{key}"
    end
  end

  def send_email(key)
    if client.email.present?
      ClientMailer.send_email(client, key, I18n.locale).deliver!
    else
      log "No email to send mail #{key}"
    end
  end

  def sms_text(key)
    template = client.vendor.mail_templates.get key: key, namespace: :client, locale: I18n.locale
    context = MailContext.new client: client, template: template
    template.to_sms context
  end

  def log(message)
    Rails.logger.info "client_id=#{client.id} #{message}"
  end
end
