module YandexKassa
  class PaymentService < CheckService
    AVISO_FAIL_CODE = 200

    def success_payment
      payment.order.order_payment.pay! payment
      super
    end

    def failed_payment
      response(AVISO_FAIL_CODE)
    end

    def response_class
      YandexKassa::PaymentService::AvisoResponse
    end
  end
end
