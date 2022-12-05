class Reporters::SalesPayments < Reporters::SalesBase
  # { payment_title => total_amount }
  def perform
    order_items
      .joins(:payment_type)
      .group('vendor_payments.id')
      .sum('order_items.price_cents * order_items.count')
      .transform_keys { |id| vendor.vendor_payments.find(id).title }
      .transform_values { |cents| Money.new(cents, vendor.default_currency) }
      .sort_by(&:second)
      .reverse
      .take(5)
      .to_h
  end
end
