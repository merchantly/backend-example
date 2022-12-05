module Starrys
  class Client
    include Virtus.model strict: true

    attribute :client_cert, String
    attribute :client_key, String
    attribute :test, Boolean, default: true

    def complex(data)
      response = post('/fr/api/v2/Complex', data.to_json)
      Starrys.logger.info "Запрос с #{data.to_json}, ответ #{response.body}"
      parse_response response
    end

    def post(path, body)
      connection.post do |req|
        req.url path
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = '*/*'
        req.body = body
      end
    end

    private

    def url
      if !test && Rails.env.production?
        'https://kkt.starrys.ru'.freeze
      else
        'https://fce.starrys.ru:4443'.freeze
      end
    end

    #=> {"ClientId"=>"<идентификатор клиента>",
    # "Date"=>{"Date"=>{"Day"=>0, "Month"=>0, "Year"=>0}, "Time"=>{"Hour"=>0, "Minute"=>0, "Second"=>0}},
    # "Device"=>{"Name"=>"10000000000000000094", "Address"=>"192.168.142.20:4094"},
    # "DeviceRegistrationNumber"=>"2505480089021269",
    # "DeviceSerialNumber"=>"10000000000000000094",
    # "DocumentType"=>0,
    # "FNSerialNumber"=>"9999999999999094",
    # "Path"=>"/fr/api/v2/Complex",
    # "RequestId"=>"<уникальный идентификатор запроса>",
    # "Response"=>{"Error"=>51, "ErrorMessages"=>["MSGCODE: 48, Неправильный параметр платежа [Код налога]: 0"]}}

    def parse_response(response)
      content_type = response.headers['content-type']
      raise "Не известный content_type #{content_type}. body=#{response.body}" unless content_type == 'application/json; charset=utf-8'

      body = JSON.parse response.body

      raise FatalResponseError.new body['ErrorDescription'], body['FCEError'] if body['Fatal'] || body['FCEError']

      r = body['Response']

      raise ResponseError.new r['ErrorMessages'] || 'Empty error message', r['Error'] if r['Error'].positive?

      body
    end

    def ssl_options
      raise 'Нет сертификата и ключа' unless client_cert.is_a?(String) && client_key.is_a?(String)

      {
        client_cert: OpenSSL::X509::Certificate.new(client_cert),
        client_key: OpenSSL::PKey::RSA.new(client_key)
      }
    end

    def connection
      @connection ||= Faraday::Connection.new url, ssl: ssl_options
    end
  end
end
