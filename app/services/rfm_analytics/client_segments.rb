# Номера сегментов RFM к которым относится клиент
# Начинается от 1
module RFMAnalytics
  class ClientSegments
    include Virtus.model struct: true

    attribute :r, Integer
    attribute :f, Integer
    attribute :m, Integer

    def valid?
      r.present? && f.present? && m.present?
    end

    def segment
      @segment ||= Segment.find(self) || raise("Не найден сегмент для #{self}")
    end

    def to_s
      [r, f, m].join.presence || '???'
    end

    def to_mask
      to_a
    end

    def to_a
      [r, f, m]
    end
  end
end
