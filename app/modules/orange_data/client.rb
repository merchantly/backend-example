module OrangeData
  class Client
    include Virtus.model strict: true

    ResponseError = Class.new StandardError

    TEST_HOST = 'https://apip.orangedata.ru:2443'.freeze
    PRODUCTION_HOST = 'https://api.orangedata.ru:12003'.freeze

    attribute :client_cert, String
    attribute :client_key, String
    attribute :private_key, String
    attribute :client_key_password, String
    attribute :env, Symbol

    def post(data)
      data_json = data.to_json

      pkey = OpenSSL::PKey::RSA.new(private_key)

      signature = Base64.strict_encode64(pkey.sign(OpenSSL::Digest.new('SHA256'), data_json))

      res = request_connection.post do |req|
        req.headers['Content-Type'] = 'application/json;charset=UTF-8'
        req.headers['X-Signature'] = signature

        req.body = data_json
      end

      return if [201, 409].include?(res.status)

      json_res = JSON.parse res.body

      raise OrangeData::Client::ResponseError.new(json_res['errors']) if json_res['errors'].present?
    end

    def get(id, inn)
      check_connection(id, inn).get do |req|
        req.headers['Content-Type'] = 'application/json;charset=UTF-8'
      end
    end

    private

    def request_connection
      Faraday::Connection.new "#{host}/api/v2/documents/", ssl: ssl_options
    end

    def check_connection(id, inn)
      Faraday::Connection.new "#{host}/api/v2/documents/#{inn}/status/#{id}", ssl: ssl_options
    end

    def host
      env == :test ? TEST_HOST : PRODUCTION_HOST
    end

    def ssl_options
      rsa_client_key = env == :test ? OpenSSL::PKey::RSA.new(client_key, client_key_password) : OpenSSL::PKey::RSA.new(client_key)

      {
        client_cert: OpenSSL::X509::Certificate.new(client_cert),
        client_key: rsa_client_key
      }
    end
  end
end
