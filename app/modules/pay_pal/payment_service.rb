module PayPal
  class PaymentService < BasePaymentService
    def perform_and_get_response
      raise OrderNotFound, 'order not found' if payment.order.blank?
      raise InvalidPayment unless payment.valid?

      return success_payment if payment.refunded?

      if payment.accepted?
        success_payment
      else
        failed_payment
      end
    rescue StandardError => e
      error_catched e
    end

    private

    def payment
      @payment ||= PayPal::PaymentService::Notify.new params, vendor
    end
  end
end
