class CouponsProduct < ApplicationRecord
  belongs_to :coupon
  belongs_to :product
end
