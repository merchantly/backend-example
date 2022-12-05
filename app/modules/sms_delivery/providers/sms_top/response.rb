module SmsDelivery
  module Providers
    module SmsTop
      class Response
        include Virtus.model

        FATAL_ERRORS = %w[102 103].freeze
        SUCCESS_CODE = '100'.freeze

        attribute :Code, String
        attribute :MessageIs, String
        attribute :valid, String
        attribute :nvalid, String
        attribute :Blocked, String
        attribute :Repeated, String
        attribute :lastuserpoints, Integer
        attribute :SMSNUmber, Integer
        attribute :totalcout, Integer
        attribute :currentuserpoints, Integer
        attribute :totalsentnumbers, Integer

        def success?
          self.Code == SUCCESS_CODE
        end

        def fail?
          !success?
        end

        def error_message
          self.MessageIs
        end

        def fatal_error?
          FATAL_ERRORS.include?(self.Code)
        end

        def soft_error?
          !fatal_error?
        end

        def self.fake
          new Code: SUCCESS_CODE
        end

        def raw
          to_json
        end
      end
    end
  end
end

# {"Code":"100",
#  "MessageIs":"\u062a\u0645 \u0627\u0633\u062a...",
#  "valid":"79674712406",
#  "nvalid":"",
#  "Blocked":"",
#  "Repeated":"",
#  "lastuserpoints":27763,
#  "SMSNUmber":1,
#  "totalcout":1,
#  "currentuserpoints":27762,
#  "totalsentnumbers":1
# }

# 100 - success
# 103 - incorrect password
# 102 - incorrect login
