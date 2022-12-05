module RussianPost
  class ResponseError < StandardError
    def initialize(messages)
      @messages = messages
    end

    def to_s
      message
    end

    def message
      @messages
    end
  end
end
