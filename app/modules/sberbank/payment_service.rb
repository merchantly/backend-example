module Sberbank
  class PaymentService < BasePaymentService
    def perform_and_get_response
      return success_response if payment.refunded?

      if payment.accepted?
        success_payment
      else
        failed_payment
      end
    end

    private

    def success_payment
      payment.order.order_payment.pay! payment.inspect
      success_response
    end

    def failed_payment
      payment.order.order_payment.fail! payment.inspect if payment.order.present?
      success_response
    end

    def success_response
      '200 OK'
    end

    def failed_response
      'ERROR'
    end

    def payment
      @payment ||= Sberbank::PaymentService::Notify.new params, vendor
    end
  end
end
