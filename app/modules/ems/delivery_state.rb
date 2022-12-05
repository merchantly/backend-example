class EMS::DeliveryState
  API_URL = 'http://postabot.ru/tr/tracker2.php'.freeze

  GET_TIMEOUT = 1

  def initialize(order_delivery)
    @order_delivery = order_delivery
  end

  # @returns EMS::Entities::Response
  #
  def get_state
    raise NoExternalId if order_delivery.tracking_id.blank?

    response = Net::HTTP.get_response uri

    EMS.logger.info message: 'Get state',
                    tags: [:ems],
                    response_body: response.body.to_s,
                    response_code: response.code.to_i,
                    order_id: order_delivery.order.id

    response = EMS::Entities::Response.parse response.body.force_encoding('UTF-8')
    raise Error unless response.persisted?

    response
  rescue DownloadTimeoutExceed
    nil
  rescue EMS::DeliveryState::NoExternalId => e
    raise e
  rescue StandardError => e
    raise Error, e.to_s
  end

  private

  attr_reader :order_delivery

  def uri
    params = {
      'track-number' => order_delivery.tracking_id,
      'carrier' => 'ems'
    }
    URI("#{API_URL}?#{params.to_query}")
  end

  class Error < StandardError
  end

  class NoExternalId < RuntimeError
  end
end
