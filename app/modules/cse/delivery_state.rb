# Описание базового API CSE http://www.cse-cargo.ru/basic_cargo_api.pdf

class CSE::DeliveryState
  API_URL = 'https://service.cse-cargo.ru/JSONWebService.asmx/'.freeze

  GET_TIMEOUT = 1

  def initialize(order_delivery)
    @order_delivery = order_delivery
  end

  # @returns CSE::Entities::Response
  #
  def get_state
    raise NoExternalId if order_delivery.tracking_id.blank?

    response = Net::HTTP.get_response uri

    CSE.logger.info message: 'Get state',
                    tags: [:cse],
                    response_body: response.body.to_s,
                    response_code: response.code.to_i,
                    order_id: order_delivery.order.id

    cse_response = CSE::Entities::Response.build_from_body response.body

    if cse_response.error.present? ||
        (cse_response.documents.first.present? && cse_response.documents.first.try(:error).present?)
      raise Error, cse_response
    else
      cse_response
    end
  rescue DownloadTimeoutExceed
    nil
  end

  private

  attr_reader :order_delivery

  def uri
    params = {
      login: order_delivery.delivery_type.login,
      password: order_delivery.delivery_type.password,
      documentType: :order,
      numberType: :internalnumber,
      number: order_delivery.tracking_id
    }
    URI("#{API_URL}Tracking?#{params.to_query}")
  end

  class Error < StandardError
    def initialize(response)
      @response = response
    end

    # Список кодов ошибок http://www.cse-cargo.ru/errors_cargo_api.pdf
    #
    MESSAGES = {
      '03010' => 'Ошибка авторизации'
    }.freeze

    def message
      if MESSAGES.key? error_info
        "#{error_info}: #{MESSAGES[error_info]}"
      else
        @response.to_json
      end
    end

    def to_s
      message
    end

    private

    def error_info
      @response.error_info.try(:strip)
    end
  end

  class NoExternalId < RuntimeError
  end
end
