module Robokassa
  class PaymentService < BasePaymentService
    def perform_and_get_response
      if payment.accepted?
        success_payment
      else
        failed_payment
      end
    end

    private

    def success_payment
      payment.order.order_payment.pay! payment
      success_response
    end

    def failed_payment
      payment.order.order_payment.fail! payment.inspect if payment.order.present?
      failed_response
    end

    def success_response
      "OK#{params['InvId']}"
    end

    def failed_response
      'ERROR'
    end

    def payment
      @payment ||= Robokassa::PaymentService::Notify.new params, vendor
    end
  end
end
