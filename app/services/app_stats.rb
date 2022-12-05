module AppStats
  def self.perform
    companies_count = Vendor.count
    selled_items_count = Order.success.sum :items_count
    total_orders_amount = ((Order.success.sum(:total_with_delivery_price_cents) / 100).to_f / 1_000_100.0).to_i

    {
      companies_count: companies_count,
      selled_items_count: selled_items_count,
      total_orders_amount: total_orders_amount
    }
  end
end
