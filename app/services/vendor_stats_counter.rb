class VendorStatsCounter
  def initialize(vendor)
    @vendor = vendor
  end

  def perform
    vendor.update_columns stats
  end

  private

  attr_reader :vendor

  def stats
    {
      success_orders_count: vendor.orders.success.count,
      success_payments_count: vendor.order_payments.success.count,
      total_orders_price_cents: vendor.orders.sum(:total_with_delivery_price_cents),
      total_orders_price_currency: vendor.default_currency.iso_code,
      total_success_orders_price_cents: vendor.orders.success.sum(:total_with_delivery_price_cents),
      total_success_orders_price_currency: vendor.default_currency.iso_code
    }
  end
end
