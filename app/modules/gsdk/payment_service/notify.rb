module Gsdk
  class PaymentService::Notify
    include VendorsHelper

    SIGNATURE = 'signature'.freeze
    ORDER_ID = 'orderId'.freeze
    STATUS = 'status'.freeze
    STATUS_SUCCESS = 'AUTHORIZED'.freeze
    GSDK_ID = 'orderReference'.freeze

    def initialize(params)
      @params = params.stringify_keys
    end

    def accepted?
      paid? && secret_accepted?
    end

    def paid?
      status == STATUS_SUCCESS
    end

    def secret_accepted?
      params[SIGNATURE].casecmp(sha256.upcase).zero?
    end

    def sha256
      text = gsdk_id + status

      hash = OpenSSL::HMAC.digest('SHA256', secret_code, text)

      Base64.encode64(hash).strip
    end

    def invoice
      @invoice ||= OpenbillInvoice.find_by(id: order_id)
    end

    def type
      @type ||= if invoice.present?
                  :invoice
                else
                  if order.present?
                    :order_payment
                  else
                    raise("unknown #{order_id}")
                  end
                end
    end

    def inspect
      params.to_hash
    end

    def order_id
      params[ORDER_ID]
    end

    def status
      params[STATUS]
    end

    def gsdk_id
      params[GSDK_ID]
    end

    def secret_code
      case type
      when :order_payment
        order_payment.payment_type.gsdk_secret_code
      when :invoice
        Secrets.gsdk.secret_code
      else
        raise 'Unknown'
      end
    end

    def order
      @order ||= Order.find_by_id(order_id)
    end

    delegate :order_payment, to: :order

    private

    attr_accessor :params
  end
end
