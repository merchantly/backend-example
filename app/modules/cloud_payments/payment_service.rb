module CloudPayments
  class PaymentService < BasePaymentService
    def initialize(vendor:, params:, hmac_token:, payload:)
      @hmac_token = hmac_token
      @payload = payload
      super vendor: vendor, params: params
    end

    def notify_pay
      # Проверяем не является ли это попытка уведомить о системном счете
      # Для development это нормально
      invoice = OpenbillInvoice.find_by id: params['InvoiceId']
      if invoice.present?
        return success_response if Rails.env.development?

        raise "Попытка уведомить об оплате системного счета #{invoice}"
      end

      validate!
      @payment = webhooks.on_pay params
      raise InvalidPayment, payment unless payment.status == 'Completed'

      success_payment
    rescue StandardError => e
      error_catched e
    end

    def notify_fail
      validate!
      @payment = webhooks.on_fail params

      failed_payment
      success_response
    rescue StandardError => e
      error_catched e

      { code: 0 } # to calm down CloudPayments
    end

    private

    attr_reader :payment, :hmac_token, :payload

    def validate!
      webhooks.validate_data! payload, hmac_token
    end

    def success_response
      { code: 0 }
    end

    def order
      @order ||= vendor.orders.find_by_external_id(payment.invoice_id) || raise(OrderNotFound)
    end

    def webhooks
      @webhooks ||= CloudPayments::Webhooks.new config
    end

    def vendor_payment
      @vendor_payment ||= vendor.vendor_payments.alive.find_by(payment_agent_type: OrderPaymentCloudPayments.name) || raise('Не найдена оплата CloudPayments')
    end

    def config
      CloudPayments::Config.new do |c|
        c.public_key = vendor_payment.cloud_payments_public_id
        c.secret_key = vendor_payment.cloud_payments_api_key
        c.logger = CloudPayments.config.logger
        c.raise_banking_errors = true
      end
    end
  end
end
