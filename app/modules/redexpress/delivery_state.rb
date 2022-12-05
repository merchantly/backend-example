# Модуль для запроса статуса заказа у Redexpress
#
# http://redexpressservice.ru:9081/rxwbm/wbmanage.asmx

module Redexpress
  class DeliveryState
    API_URL = 'http://redexpressservice.ru:9081/'.freeze

    GET_TIMEOUT = 1

    def initialize(order_delivery)
      @order_delivery = order_delivery
    end

    # @return Redexpress::Entities::Mails
    #
    def get_state
      response = Net::HTTP.get_response uri

      Redexpress.logger.info message: 'Get state', tags: [:redexpress], response_body: response.body.to_s, response_code: response.code.to_i, order_id: order_delivery.order.id

      raise Error, response.code unless response.code.to_i == 200

      # redexpress выдает пустое содержие если такого заказа нет
      #
      Redexpress::Entities::Mails.parse response.body
    rescue DownloadTimeoutExceed
      nil
    rescue StandardError => e
      raise Error, e.to_s
    end

    private

    attr_reader :order_delivery

    def uri
      params = { mailcode: order_delivery.tracking_id }
      URI("#{API_URL}rxwbm/invoiceinfo?#{params.to_query}")
    end

    class Error < StandardError
    end
  end
end
