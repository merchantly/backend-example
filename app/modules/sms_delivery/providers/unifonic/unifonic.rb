module SmsDelivery
  module Providers
    module Unifonic
      class Unifonic < SmsDelivery::Providers::BaseProvider
        SERVICE_URL = 'http://api.unifonic.com'.freeze
        SERVICE_PATH = '/wrapper/sendSMS.php'.freeze

        def call
          return Response.fake if Rails.env.test?

          response = conn.post do |req|
            req.url SERVICE_PATH
            req.body = {
              userid: Secrets.unifonic.login,
              password: Secrets.unifonic.password,
              sender: Secrets.unifonic.sender,
              to: phones.join(', '),
              msg: message
            }
          end

          SmsDelivery::Providers::Unifonic::Response.new response: response
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

# example
# SmsDelivery::Providers::Unifonic::Unifonic.new(phones: ['+79677777777'], message: "test SMS").call
