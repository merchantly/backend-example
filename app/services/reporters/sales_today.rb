class Reporters::SalesToday < Reporters::SalesBase
  class Report
    include Virtus.model

    attribute :total_amount, Money
    attribute :average_amount, Money
    attribute :orders_count, Integer
    attribute :top_selling_items # { good_title => [count, percent] }
  end

  def perform
    Report.new(
      total_amount: Money.new(order_items.sum('order_items.price_cents * order_items.count'), vendor.default_currency),
      average_amount: Money.new(order_items.average('orders.total_price_cents'), vendor.default_currency),
      orders_count: order_items.map(&:order_id).uniq.count,
      top_selling_items: top_selling_items
    )
  end

  # { good_title => [count, percent] }
  def top_selling_items
    total_count = order_items.sum(:count)

    all_items = order_items.group(:good_type, :good_id).count(:count)
      .transform_keys { |k| k.first.present? ? k.first.constantize.find(k.second).title : 'Custom Amount' }
      .sort_by { |_, v| v }
      .reverse

    first_items = all_items.first(4)

    last_item = ['Other items', (all_items - first_items).reduce(0) { |a, e| a + e.second }]

    (first_items + [last_item])
      .to_h
      .transform_values { |v| [v, ((v.to_f / total_count) * 100)] }
  end
end
