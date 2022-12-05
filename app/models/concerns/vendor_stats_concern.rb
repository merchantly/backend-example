module VendorStatsConcern
  extend ActiveSupport::Concern

  included do
    monetize :total_orders_price_cents,
             as: :total_orders_price

    monetize :total_success_orders_price_cents,
             as: :total_success_orders_price

    before_validation on: :create do
      self.total_success_orders_price = zero_money
      self.total_orders_price = zero_money
    end
  end

  def total_orders_success
    return if total_orders_price_cents.to_i.zero?

    (100.0 * total_success_orders_price_cents / total_orders_price_cents).to_i
  end
end
