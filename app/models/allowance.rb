class Allowance < Coupon
  validates :discount, presence: true,
                       numericality: { greater_than: :min_cart_discount, less_than_or_equal_to: :max_cart_discount },
                       if: proc { |coupon| coupon.discount_type.percent? && coupon.level.equal?(:cart) }

  validates :discount, presence: true,
                       numericality: { greater_than: :min_item_discount, less_than_or_equal_to: :max_item_discount },
                       if: proc { |coupon| coupon.discount_type.percent? && coupon.level.equal?(:item) }

  validates :discount, presence: true,
                       numericality: { greater_than: 0 },
                       if: proc { |coupon| coupon.discount_type.fixed? }

  before_validation do
    self.use_count = 1
  end

  private

  def max_cart_discount
    vendor.max_allowance_cart_level_discount_percent.presence || 100
  end

  def min_cart_discount
    vendor.min_allowance_cart_level_discount_percent.presence || 0
  end

  def max_item_discount
    vendor.max_allowance_item_level_discount_percent.presence || 100
  end

  def min_item_discount
    vendor.min_allowance_item_level_discount_percent.presence || 0
  end
end
