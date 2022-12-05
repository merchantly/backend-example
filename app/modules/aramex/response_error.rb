module Aramex
  class ResponseError < StandardError
    def initialize(res)
      @messages = res.to_s
    end

    def to_s
      message
    end

    def message
      @messages.to_s
    end
  end
end
