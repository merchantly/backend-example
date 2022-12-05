module RepeatDeadLock
  TRIES = 3

  def self.perform(&_block)
    tries = 1
    begin
      yield
    rescue PG::TRDeadlockDetected => e
      binding.debug_error
      Rails.logger.error "Try #{tries} of #{TRIES}: #{e}"
      if (tries += 1) < TRIES
        retry
      else
        raise TriesExceed.new(error: e, count: tries)
      end
    end
  end

  class TriesExceed < StandardError
    def initialize(error: nil, count: nil)
      @error = error
      @count = count
    end

    def message
      "Tries exceed #{@count} with error #{@error}"
    end
  end
end
