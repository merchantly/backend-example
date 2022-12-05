module ArsenalPay
  class PaymentService < BasePaymentService
    def initialize(params:)
      @params = params
    end

    def perform_and_get_response
      return success_response if payment.refunded? || payment.check?

      if payment.reversal?
        failed_payment!
        return success_response
      end

      if payment.accepted?
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
      if payment.check?
        payment.ofd? ? receipt : 'YES'
      elsif payment.payment?
        payment.format == 'json' ? { response: 'OK' } : 'OK'
      else
        'OK'
      end
    end

    def failed_response
      'ERR'
    end

    def payment
      @payment ||= ArsenalPay::PaymentService::Notify.new params
    end

    def receipt
      ArsenalPayReceipt.new(order: payment.order).data
    end
  end
end
