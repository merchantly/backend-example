require 'net/http'

module W1
  class OpenApi
    class ErrorResponse < StandardError
      attr_reader :resp

      def initialize(resp)
        @resp = resp
      end

      def message
        "[#{resp.code}]: #{resp.response}"
      end
    end

    class Unauthorized < StandardError
    end

    GET_TIMEOUT = 1
    API_URL = 'https://api.w1.ru/OpenApi/'.freeze

    def initialize(token)
      @token = token
    end

    def get_balance(currency_id = nil)
      path = currency_id ? "balance/#{currency_id}" : 'balance'
      prepare_entity get(path), W1::Entities::Balance
    rescue DownloadTimeoutExceed, Unauthorized
      # ignore
      nil
    rescue StandardError => e
      Bugsnag.notify e
      binding.debug_error
      nil
    end

    private

    attr_reader :token

    def prepare_entity(result, entity_class)
      if result.is_a? Array
        result.map { |e| entity_class.new e }
      else
        entity_class.new result
      end
    end

    def get(path)
      uri = URI.parse API_URL + path

      http = Net::HTTP.start uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE # OpenSSL::SSL::VERIFY_PEER
      req = Net::HTTP::Get.new uri, headers
      response = http.request req

      case response.code
      when '200'
        parse_response response
      when '401'
        raise Unauthorized
      else
        raise ErrorResponse.new(response)
      end
    end

    def headers
      {
        'Accept' => 'application/vnd.wallet.openapi.v1+json',
        'Content-Type' => 'application/vnd.wallet.openapi.v1+json',
        'Authorization' => "Bearer #{token}"
      }
    end

    def parse_response(response)
      case response.content_type
      when /xml/
        Hash.from_xml Nokogiri::XML(response.body).to_xml
      when /json/
        MultiJson.load response.body
      else
        raise "Unknown response content_type #{response.content_type}"
      end
    rescue REXML::ParseException, MultiJson::ParseError => e
      Bugsnag.notify e, metaData: { response: response }
      {}
    end
  end
end
