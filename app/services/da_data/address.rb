module DaData
  class Address
    include Virtus.model

    API_URL = 'https://dadata.ru/api/v2/clean/address'.freeze

    attribute :raw_address, String

    def call
      parse response
    rescue StandardError => e
      Bugsnag.notify e, metaData: { raw_address: raw_address }
      {}
    end

    private

    def response
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Post.new(uri.path, headers)
      request.body = request_body
      http.request request
    end

    def parse(response)
      MultiJson.load(response.body).first.symbolize_keys
    end

    def uri
      URI.parse API_URL
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Token #{api_key}",
        'X-Secret' => secret_key
      }
    end

    def request_body
      [raw_address].to_json
    end

    delegate :api_key, :secret_key, to: 'Secrets.dadata'
  end
end
