class ApiError
  attr_reader :code, :message, :errors, :http_code

  def initialize(code:, message:, errors:, http_code:)
    @code = code
    @message = message
    @errors = errors
    @http_code = http_code
  end

  def to_hash
    {
      code: code,
      message: message,
      errors: errors
    }
  end
end
