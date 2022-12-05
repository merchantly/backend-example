class Aqsi::Client
  include Virtus.model

  TEST_URL = 'https://aqsi.ru:8001'.freeze
  URL = 'https://aqsi.ru:8000'.freeze

  attribute :client_key, String
  attribute :test_mode, Boolean

  def create_order(data)
    result = connection('/api/v1/pub/Orders/simple').post do |req|
      req.headers['Content-type'] = 'application/json'
      req.headers['x-client-key'] = "Application #{client_key}"
      req.body = data.to_json
    end

    response result
  end

  def delete_order(uuid)
    result = connection("/api/v1/pub/Orders/simple/#{uuid}").delete do |req|
      req.headers['x-client-key'] = "Application #{client_key}"
    end

    response result
  end

  def create_client(data)
    result = connection('/api/v1/pub/Clients').post do |req|
      req.headers['Content-type'] = 'application/json'
      req.headers['x-client-key'] = "Application #{client_key}"
      req.body = data.to_json
    end

    response result
  end

  private

  def response(result)
    res = JSON.parse result.body

    raise Aqsi::ResponseError.new(res) if res['errors'].present?

    res
  end

  def connection(endpoint)
    Faraday::Connection.new "#{url}#{endpoint}"
  end

  def url
    test_mode ? TEST_URL : URL
  end
end
