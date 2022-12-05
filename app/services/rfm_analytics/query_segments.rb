# Объект хранит характеристики сегментов магазина
#
# RFM-анализ — это техника сегментации клиентов, опирающаяся на их поведение.
#
# Recency (R) — давность, количество времени с прошлой покупки
# Frequency (F) — частота, общее количество покупок
# Monetary (M) — деньги, общая сумма покупок
#
module RFMAnalytics
  class QuerySegments
    include Virtus.model struct: true

    attribute :count, Integer

    attribute :days, Integer
    attribute :max_orders_count, Integer
    attribute :max_total_orders_price, Money
    attribute :min_total_orders_price, Money

    attribute :r, Array
    attribute :f, Array
    attribute :m, Array
  end
end
