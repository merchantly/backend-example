class Promotion < Coupon
  validates :discount, presence: true,
                       numericality: { greater_than: 0, less_than_or_equal_to: 100 },
                       if: proc { |coupon| coupon.discount_type.percent? }

  validates :discount, presence: true,
                       numericality: { greater_than: 0 },
                       if: proc { |coupon| coupon.discount_type.fixed? }
  before_validation do
    self.use_count = nil
    self.is_enabled = true
  end

  def discounted_price(price)
    if discount_type.fixed?
      result = price - discount_price

      return vendor.zero_money if result <= vendor.zero_money

      result
    else
      dp = (price * discount / 100).exchange_to price.currency
      return vendor.zero_money if dp >= price

      price - dp
    end
  end
end
