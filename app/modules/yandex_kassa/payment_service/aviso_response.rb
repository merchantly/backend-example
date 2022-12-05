module YandexKassa
  class PaymentService::AvisoResponse
    include HappyMapper

    tag :paymentAvisoResponse

    attribute :code, String, tag: :code
    attribute :performed_datetime, String, tag: :performedDatetime
    attribute :invoice_id, String, tag: :invoiceId
    attribute :shop_id, String, tag: :shopId

    def inspect
      to_xml
    end
  end
end
