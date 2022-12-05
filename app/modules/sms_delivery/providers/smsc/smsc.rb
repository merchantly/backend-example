module SmsDelivery
  module Providers
    module Smsc
      class Smsc < SmsDelivery::Providers::BaseProvider
          SERVICE_URL = 'https://smsc.ru'.freeze
          SERVICE_PATH = '/sys/send.php'.freeze

          def call
            return Response.fake if Secrets.smsc.fake || Rails.env.test?

            raw_response = conn.post do |req|
              req.url SERVICE_PATH
              req.body = {
                login: Secrets.smsc.login,
                psw: Secrets.smsc.password,
                phones: phones.join(', '),
                mes: message,
                charset: 'utf-8',
                sender: Secrets.smsc.sender,
                fmt: 2
              }
            end

            SmsDelivery::Providers::Smsc::Response.parse raw_response.body.force_encoding('utf-8')
          end

        private

          def conn
            @conn ||= Faraday.new(url: SERVICE_URL) do |faraday|
              faraday.request  :url_encoded
              faraday.response :logger if Rails.env.development?
              faraday.adapter  Faraday.default_adapter
            end
          end
      end
    end
  end
end
