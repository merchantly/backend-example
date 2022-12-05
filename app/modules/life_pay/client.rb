module LifePay
  class Client
    URL = 'https://sapi.life-pay.ru'.freeze # /cloud-print/create-receipt
    include Virtus.model strict: true

    attribute :apikey, String
    attribute :login, String
    attribute :test, Boolean, default: true

    def create_receipt(data)
      data.merge!(
        apikey: apikey,
        login: login,
        test: test ? 1 : 0,
        mode: :email
      )

      response = post '/cloud-print/create-receipt', data
      response.body.force_encoding('utf-8')
      LifePay.logger.info "Запрос с #{data.to_json}, ответ #{response.body}"
      parse_response response
    end

    def post(path, body)
      connection.post do |req|
        req.url path

        req.headers['Accept'] = '*/*'
        req.body = body.to_json
      end
    end

    private

    def parse_response(response)
      content_type = response.headers['content-type']
      raise "Не известный content_type #{content_type}. body=#{response.body}" unless content_type == 'application/json; charset=UTF-8'

      body = JSON.parse response.body

      code = body['code']

      raise ResponseError.new body['message'], code unless code.zero?

      body
    end

    def connection
      @connection ||= Faraday::Connection.new URL
    end
  end
end
