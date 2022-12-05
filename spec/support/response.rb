module RspecRequestSupport
  def response_json
    JSON.parse response.body
  end
end

RSpec.configure do |config|
  config.include RspecRequestSupport
end
