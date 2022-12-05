module Starrys
  class ResponseError < StandardError
    def initialize(messages, error_id)
      @messages = messages
      @messages = @messages.join('; ') if @messages.is_a? Enumerable
      @error_id = error_id
    end

    def to_s
      message
    end

    def message
      "[#{@error_id}] #{@messages}"
    end
  end
end
