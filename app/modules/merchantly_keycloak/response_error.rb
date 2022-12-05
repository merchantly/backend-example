class MerchantlyKeycloak::ResponseError < StandardError
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def message
    "error: #{response['error']}, description: #{response['error_description']}"
  end
end
