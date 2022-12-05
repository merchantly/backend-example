module SmsDelivery
  module Providers
    module Unifonic
      class Response
        include Virtus.model

        attribute :response, Faraday::Response

        def success?
          response.status == 200
        end

        def fail?
          !success?
        end

        def error_message
          self.MessageIs
        end

        def fatal_error?
          fail?
        end

        def soft_error?
          fail?
        end

        def self.fake
          new response: Faraday::Response.new(status: 200)
        end

        def raw
          { raw: response.to_s }
        end
      end
    end
  end
end
