class Aqsi::ResponseError < StandardError
  def initialize(res)
    @messages = "code: #{res['code']}, message: #{res['errors']}"
  end

  def to_s
    message
  end

  def message
    @messages.to_s
  end
end
