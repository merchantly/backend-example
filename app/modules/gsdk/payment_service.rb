module Gsdk
  class PaymentService < BasePaymentService
    def initialize(params:)
      @params = params
    end

    def perform_and_get_response
      if payment.accepted?
        success_payment
      else
        failed_payment
      end
    end

    private

    def success_payment
      case payment.type
      when :order_payment
        payment.order_payment.pay! payment.inspect
        payment.order_payment.update! gsdk_payment_uuid: payment.gsdk_id
      when :invoice
        Billing::IncomeFromGsdk.perform payment.invoice
      else
        raise 'Unknown'
      end

      success_response
    end

    def failed_payment
      case payment.type
      when :order_payment
        payment.order_payment.fail! payment.inspect if payment.order_payment.present?
      when :invoice
        Billing.logger.error "Gsdk fail: #{payment.inspect}"
      else
        raise 'Unknown'
      end

      failed_response
    end

    def success_response
      Gsdk::GSDK_RESPONSE_SUCCESS
    end

    def failed_response
      Gask::GSDK_RESPONSE_ERROR
    end

    def payment
      @payment ||= Gsdk::PaymentService::Notify.new params
    end
  end
end
