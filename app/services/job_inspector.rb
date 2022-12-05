# Класс для учета прогресса у job
#
module JobInspector
  class Base
    attr_reader :total, :current, :details

    def initialize
      @total = 100
      @current = 0
    end

    def progress=(percent)
      self.current = percent.to_f * total.to_f / 100.to_f
    end

    def progress
      100 * current.to_f / total.to_f
    end

    def current=(value)
      @current = value
      update
    end

    def total=(value)
      @total = value
      update
    end

    def details=(value)
      @details = value
      update
    end

    def increment
      self.current += 1
    end

    def finish(message = nil)
      self.details = message if message.present?
      self.progress = 100
    end

    def error(message)
      self.details = message
    end

    private

    def update
      # update you database
    end
  end

  class VendorJobInspector < Base
    def initialize(vendor_job)
      @vendor_job = vendor_job
      super()
    end

    private

    def update
      vendor_job.update_inspector!
    end

    attr_reader :vendor_job
  end
end
