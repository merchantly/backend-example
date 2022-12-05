module RussianPost
  class Client
    URL = 'https://otpravka-api.pochta.ru/1.0/user/backlog'.freeze
    DELETE_URL = 'https://otpravka-api.pochta.ru/1.0/backlog'.freeze
    include Virtus.model strict: true

    attribute :token, String
    attribute :key, String

    def post(data)
      connection.put do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json;charset=UTF-8'
        req.headers['Authorization'] = "AccessToken #{token}"
        req.headers['X-User-Authorization'] = "Basic #{key}"

        req.body = data.to_json
      end
    end

    def delete(data)
      delete_connection.delete do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json;charset=UTF-8'
        req.headers['Authorization'] = "AccessToken #{token}"
        req.headers['X-User-Authorization'] = "Basic #{key}"

        req.body = data.to_json
      end
    end

    private

    def connection
      @connection ||= Faraday::Connection.new URL
    end

    def delete_connection
      @delete_connection ||= Faraday::Connection.new DELETE_URL
    end
  end
end
