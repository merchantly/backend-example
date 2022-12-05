module SmsDelivery
  class Sender
    NO_SEND_PERIOD = Client::REQUEST_TIMEOUT
    include Virtus.model
    BaseError = Class.new StandardError

    # не хватает баланса для отправки
    NotEnoughBalanceError = Class.new BaseError

    # нельзя отправлять смс на одинаковые номера с одинаковым текстом за 1 день
    ResendingError = Class.new BaseError

    # Ошибка отарвки SMS. Например кончились средства на балансе провайдера
    SendingError = Class.new BaseError

    PROVIDERS = [
      SmsDelivery::Providers::Qtelecom::Qtelecom,
      SmsDelivery::Providers::Smsc::Smsc,
      SmsDelivery::Providers::SmsTop::SmsTop,
      SmsDelivery::Providers::Unifonic::Unifonic
    ].freeze

    attribute :phones, Array
    attribute :vendor, Vendor
    attribute :message, String
    attribute :provider

    def call
      raise ResendingError if too_much_messages?
      raise NotEnoughBalanceError if vendor.present? && !vendor.sms_count.positive?

      Rails.logger.debug { "Send SMS to #{phones} from #{vendor} with text #{message}" } if Rails.env.development?

      begin
        response = provider.new(phones: phones, vendor: vendor, message: message).call
      rescue StandardError => e
        raise SendingError, e.message
      end

      raise SendingError, response.error_message if response.fail? && response.fatal_error?

      log_sms response
    end

    def log_sms(response)
      VendorSmsLogEntity.create!(
        vendor_id: vendor.try(:id),
        message: message,
        sms_count: sms_count,
        phones: phones,
        is_success: response.success?,
        result: response.raw,
        key: sms_key
      )
    rescue StandardError => e
      Bugsnag.notify e, metaData: { record: e.try(:record), phones: phones, message: message, sms_key: sms_key, response: response.raw }
      raise e
    end

    def sms_key
      Digest::MD5.hexdigest([vendor.try(:id), message, phones, Date.current].join(':'))
    end

    def message=(new_message)
      super new_message.strip.chomp
    end

    def phones=(new_phones)
      process_phones = new_phones
      process_phones = process_phones.to_s.split(/,\s/) unless process_phones.is_a? Array
      process_phones.map! { |phone| phone.sub '+', '' }
      super process_phones
    end

    private

    def sms_count
      @sms_count ||= SmsCountCalculator.new(phones: phones, message: message).call
    end

    # Вполне возможно что нужно запретить вообще отправлять повторно любые
    # сообщения кроме отправки пин-кодов
    def too_much_messages?
      VendorSmsLogEntity
        .where(key: sms_key)
        .exists?(['created_at>=?', NO_SEND_PERIOD.ago])
    end
  end
end
