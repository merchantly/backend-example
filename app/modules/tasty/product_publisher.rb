class Tasty::ProductPublisher
  include Virtus.model
  MAX_TRIES = 4
  ENDPOINT = '/v1/entries/image.json'.freeze

  attribute :product, Product
  attribute :tasty_user_token, String
  attribute :tasty_tlog_id, String

  def call
    request_retry do
      http = Net::HTTP.new Tasty::API_URL

      req = Net::HTTP::Post.new ENDPOINT, headers
      req.set_form_data form_data
      res = http.request(req)

      raise Error, res.code unless res.code.to_i == 201

      res = JSON.parse res.body
      res['id']
    end
  rescue StandardError => e
    Bugsnag.notify e, form_data: form_data
    raise e
  end

  private

  def form_data
    @form_data ||= Tasty::ProductParamsBuilder.new(product: product, tasty_tlog_id: tasty_tlog_id).as_json
  end

  def headers
    { 'X-User-Token' => tasty_user_token }
  end

  def request_retry
    tries = 1
    begin
      yield
    rescue StandardError => e
      raise e unless tries < MAX_TRIES

      tries += 1
      sleep 1
      retry
    end
  end

  class Error < StandardError
  end
end
