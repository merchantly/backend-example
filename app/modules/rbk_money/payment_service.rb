module RbkMoney
  class PaymentService < BasePaymentService
    def initialize(vendor:, params:, headers:, data:)
      @headers = headers
      @data = data

      super vendor: vendor, params: params
    end

    def perform_and_get_response
      raise OrderNotFound, 'order not found' if payment.order.blank?

      if payment.accepted?
        success_payment
      else
        failed_payment
      end
    rescue StandardError => e
      error_catched e
    end

    def success_payment
      payment.order.order_payment.pay! payment.inspect
      success_response
    end

    def failed_payment
      payment.order.order_payment.fail! payment.inspect if payment.order.present?
      failed_response
    end

    private

    attr_reader :headers, :data

    def success_response
      'OK'
    end

    def failed_response
      'ERROR'
    end

    def payment
      @payment ||= RbkMoney::PaymentService::Notify.new params, headers, data, vendor
    end
  end
end
