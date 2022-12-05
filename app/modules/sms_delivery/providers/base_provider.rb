module SmsDelivery
  module Providers
    class BaseProvider
      include Virtus.model

      attribute :phones, Array
      attribute :vendor, Vendor
      attribute :message, String

      def call
        raise 'not implemented'
      end

      private

      def send
        raise 'must be redefined'
      end
    end
  end
end
