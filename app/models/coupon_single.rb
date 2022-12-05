class CouponSingle < Coupon
  # Не валюта, а просто число
  validates :discount, presence: true
  validates :discount, numericality: { greater_than: 0, less_than_or_equal_to: 100 },
                       if: proc { |coupon| coupon.discount_type.percent? && !coupon.free_delivery? }

  validates :discount, numericality: { greater_than: 0 },
                       if: proc { |coupon| coupon.discount_type.fixed? && !coupon.free_delivery? }
end
