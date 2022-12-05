require 'open-uri'

module PayPal
  class PaymentService::Notify
    include VendorsHelper
    attr_accessor :params, :vendor

    ORDER_ACCEPTED = 'Completed'.freeze
    ORDER_REFUNDED = 'Refunded'.freeze

    def initialize(params, vendor)
      @params = params
      @vendor = vendor
    end

    def valid?
      order.total_with_delivery_price.to_s == order_amount && pay_pal_validate?
    end

    def pay_pal_validate?
      return true if Rails.env.test?

      pay_pal_params = { cmd: '_notify-validate' }.merge! params

      conn = Faraday.new(url: order.order_payment.payment_url) do |faraday|
        faraday.request :url_encoded # form-encode POST params
        faraday.response :logger # log requests to STDOUT
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
      page = conn.get '', pay_pal_params

      return true if page.body.gsub(/\s+/, '') == 'VERIFIED'
    rescue ArgumentError => e
      if e.message.include?('invalid byte sequence')
        vendor.bells_handler.add_error PayPal::InvalidByteError.new
      else
        raise e
      end
    end

    def accepted?
      state.present? && state == ORDER_ACCEPTED
    end

    def refunded?
      state == ORDER_REFUNDED
    end

    def order
      @order ||= vendor.orders.find_by_id(order_id) || raise("Не найден заказ #{order_id}")
    end

    def custom
      @custom ||= JSON.parse params[PAYPAL_CUSTOM]
    end

    def order_id
      custom[PAYPAL_ORDER_ID]
    end

    def order_amount
      custom[PAYPAL_ORDER_AMOUNT]
    end

    private

    def state
      params[PAYPAL_PAYMENT_STATUS]
    end
  end
end
