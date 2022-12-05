# RFM-анализ клиентов
# http://lpgenerator.ru/blog/2016/08/04/kak-uvelichit-prodazhi-segmentaciya-klientov-i-rfm-analiz/
# https://joaocorreia.io/blog/rfm-analysis-increase-sales-by-segmenting-your-customers.html
#
# RFM-анализ — это техника сегментации клиентов, опирающаяся на их поведение.
#
# Recency (R) — давность, количество времени с прошлой покупки
# Frequency (F) — частота, общее количество покупок
# Monetary (M) — деньги, общая сумма покупок
#
module RFMAnalytics
  class SegmentsBuilder
    COUNT = 4
    include Virtus.model

    attribute :vendor, Vendor, struct: true

    def build
      QuerySegments.new(
        count: COUNT,
        days: days,
        max_orders_count: max_orders_count,
        max_total_orders_price: max_total_orders_price,
        min_total_orders_price: min_total_orders_price,
        r: build_recency,
        f: build_frequency,
        m: build_money
      ).freeze
    end

    private

    delegate :clients, :orders, to: :vendor

    attr_accessor :segments

    def from
      @from ||= orders.minimum(:created_at)
    end

    def to
      @to ||= Time.zone.now
    end

    def max_orders_count
      @max_orders_count ||= clients.maximum(:orders_count) || 0
    end

    def max_total_orders_price
      @max_total_orders_price ||= Money.new clients.maximum(:total_orders_price_cents).to_i, vendor.default_currency
    end

    def min_total_orders_price
      @min_total_orders_price ||= Money.new clients.minimum(:total_orders_price_cents).to_i, vendor.default_currency
    end

    def days
      return 0 if to.nil? || from.nil?

      to.to_date - from.to_date
    end

    def build_frequency
      return [3, 2, 1, 0] if max_orders_count < 4

      quarter = max_orders_count.to_f / 4
      half = max_orders_count / 2

      [
        max_orders_count - quarter,
        half,
        quarter,
        0
      ]
    end

    def build_money
      quarter = max_total_orders_price / 4
      half = max_total_orders_price / 2

      [
        (max_total_orders_price - quarter).cents,
        half.cents,
        quarter.cents,
        0
      ]
    end

    def build_recency
      return [3, 2, 1, 0] if days < 4

      quarter = days / 4
      half = days / 2
      [
        quarter,
        half,
        days - quarter,
        days,
      ]
    end
  end
end
