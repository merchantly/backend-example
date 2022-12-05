module Tinkoff
  class PaymentService < BasePaymentService
    def perform_and_get_response
      return success_response if payment.authorized? || payment.partial_refunded? || payment.refunded?

      if payment.rejected? || payment.canceled?
        failed_payment! unless payment.order.paid?

        success_response
      elsif payment.accepted?
        success_payment!

        success_response
      else
        failed_payment!

        failed_response
      end
    end

    private

    def success_payment!
      payment.order.order_payment.pay! payment.inspect
    end

    def failed_payment!
      payment.order.order_payment.fail! payment.inspect if payment.order.present?
    end

    def success_response
      'OK'
    end

    def failed_response
      'ERROR'
    end

    def payment
      @payment ||= Tinkoff::PaymentService::Notify.new params, vendor
    end
  end
end
