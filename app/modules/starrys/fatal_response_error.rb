module Starrys
  class FatalResponseError < ResponseError
    def initialize(message, error_id)
      super [message], error_id
    end
  end
end
