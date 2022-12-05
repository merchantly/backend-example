module SmsDelivery
  module Providers
    module SmsTop
      class SmsTop < SmsDelivery::Providers::BaseProvider
        HOST = 'http://www.sms-top.com/api/sendsms.php'.freeze
        SENDER = 'Geidea'.freeze
        UNICODE = 'e'.freeze
        RETURN = 'json'.freeze
        RM = 1

        def call
          return Response.fake if Secrets.sms_top.nil? || Secrets.sms_top.fake

          raw_response = Faraday.post(HOST, params)

          response = JSON.parse(raw_response).symbolize_keys

          SmsDelivery::Providers::SmsTop::Response.new response
        end

        private

        def params
          {
            username: Secrets.sms_top.username,
            password: Secrets.sms_top.password,
            message: message,
            numbers: phones.join(','),
            sender: SENDER,
            unicode: UNICODE,
            Rmduplicated: RM,
            return: RETURN
          }
        end
      end
    end
  end
end
