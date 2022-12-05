module YandexKassa
  class CheckService
    SUCCESS_CODE = 0
    CHECK_FAIL_CODE = 100

    def initialize(vendor: nil, params: nil)
      @vendor = vendor
      @params = params
    end

    def perform_and_get_response
      raise OrderNotFound, 'order not found' if payment.order.blank?

      if payment.accepted?
        YandexKassa.logger.info "Vendor #{vendor.id}, order #{payment.order.id}, payment #{params} accepted"
        success_payment
      else
        YandexKassa.logger.warn "Vendor #{vendor.id}, order #{payment.order.id}, secret is wrong" unless payment.secret_accepted?
        YandexKassa.logger.warn "Vendor #{vendor.id}, order #{payment.order.id}, payment #{params} IS NOT ACCEPTED"
        failed_payment
      end
    end

    private

    attr_reader :vendor, :params

    def payment
      @payment ||= YandexKassa::PaymentService::Notify.new params, vendor
    end

    def success_payment
      response(SUCCESS_CODE)
    end

    def failed_payment
      response(CHECK_FAIL_CODE)
    end

    def response(code)
      success = response_class.new
      success.code = code
      success.performed_datetime = request_datetime
      success.invoice_id = invoice_id
      success.shop_id = shop_id
      success
    end

    def response_class
      YandexKassa::PaymentService::CheckResponse
    end

    def request_datetime
      params[REQUEST_DATETIME]
    end

    def invoice_id
      params[INVOICE_ID]
    end

    def shop_id
      params[SHOP_ID]
    end
  end
end
