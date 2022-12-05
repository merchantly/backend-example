module Bitrix24
  class Requestor
    include Virtus.model strict: true

    attribute :order, Order

    def perform
      logger.info "Старт экспорта заказа: vendor_id: #{order.vendor_id}, order_id: #{order.id}"

      Bitrix24::Client.new(vendor: order.vendor).add_deal(order)

      logger.info "Экспорт заказа успешен: vendor_id: #{order.vendor_id}, order_id: #{order.id}"
    rescue StandardError => e
      Bugsnag.notify e
      logger.error "Произошла ошибка: order_id: #{order.id}, message: #{e}"
      order.vendor.bells_handler.add_error e, error: e.to_s if e.is_a?(Bitrix24::Client::AuthorizationCodeError)
    end

    private

    def logger
      @logger ||= Bitrix24::Logger.new(vendor_bitrix24: order.vendor.vendor_bitrix24)
    end
  end
end
