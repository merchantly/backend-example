module SmsDelivery
  module Providers
    module Qtelecom
      class Qtelecom < SmsDelivery::Providers::BaseProvider
        SERVICE_URL = 'https://service.qtelecom.ru'.freeze
        SERVICE_PATH = '/public/http/'.freeze
        SEND_SMS_ACTION = 'post_sms'.freeze
        GZIP = 'none'.freeze

        def call
          return Response.fake if Rails.env.development?
          return Response.fake if Secrets.qtelecom.fake

          raw_response = conn.post do |req|
            req.url SERVICE_PATH
            req.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
            req.body = {
              user: Secrets.qtelecom.login,
              pass: Secrets.qtelecom.password,
              target: phones.join(', '),
              message: message,
              gzip: GZIP,
              action: SEND_SMS_ACTION,
              sender: Secrets.qtelecom.sender
            }
          end

          content = raw_response.body.force_encoding('utf-8')
          SmsDelivery::Providers::Qtelecom::Response.parse content
        rescue Nokogiri::XML::SyntaxError => e
          Bugsnag.notify e, metaData: { content: content }
          raise e
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
