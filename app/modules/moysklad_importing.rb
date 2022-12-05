module MoyskladImporting
  extend AutoLogger

  MAX_RESOURCES_COUNT = 6000

  Error = Class.new StandardError
  class NoLogin < Error
    def to_s
      message
    end

    def message
      'Не указан логин и пароль для МоегоСклада'
    end
  end

  class MaxResourcesCountError < Error
    def to_s
      message
    end

    def message
      "Количесто ресурсов больше #{MAX_RESOURCES_COUNT}"
    end
  end

  class AlreadySyncing < Error
    def initialize(ids)
      @ids = ids
    end

    def to_s
      message
    end

    def message
      "Синхронизация уже идет (#{@ids})"
    end
  end

  class NoLogEntity < Error
  end
end
