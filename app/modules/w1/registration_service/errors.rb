class W1::RegistrationService
  RegistrationError = Class.new HumanizedError

  FailResponseError = Class.new StandardError

  class ResponseError < StandardError
    def initialize(response_code, response_json, request_body = nil)
      @response_code = response_code
      @response_json = response_json
      @request_body  = request_body
    end

    def self.detect?(error_name)
      self::NAME == error_name
    end

    def to_s
      message
    end

    def message
      "[#{response_code}] #{response_json}. #{request_body}"
    end

    def description
      response_json['ErrorDescription']
    end

    def name
      response_json['Error']
    end

    private

    attr_reader :response_code, :response_json, :request_body
  end

  class EmailExistsError < ResponseError
    NAME = 'EMAIL_ALREADY_EXISTS'.freeze
  end

  class ParamFormatError < ResponseError
    NAME = 'PARAM_FORMAT_ERROR'.freeze

    def to_s
      message
    end

    def message
      [description, params].compact.join('; ')
    end

    private

    def params
      response_json['Params']
    end
  end

  UnknownError = Class.new ResponseError

  DETECTABLE_ERRORS = [EmailExistsError, ParamFormatError].freeze
end
