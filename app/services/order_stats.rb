class OrderStats
  include Virtus.model

  attribute :vendor, Vendor
  attribute :period, Range, default: (3.months.ago)..Time.zone.now

  def call
    StatsResult.new total_price: total_price, chart_data: chart_data
  end

  private

  def total_price
    Money.new(total_cents, vendor.currency_iso_code)
  end

  def chart_data
    # TODO: находить средние значения за бОльшие промежутки (недели)
    basic_scope.pluck(:total_price_cents).each_with_index.map { |p, i| [i, p] }
  end

  def total_cents
    # TODO: учитывать валюту магазина
    basic_scope.sum :total_price_cents
  end

  def basic_scope
    vendor.orders.finished.where(created_at: period)
  end

  class StatsResult
    include Virtus.model

    attribute :total_price, Money
    attribute :chart_data, Array
  end
end
