class CategoriesCoupon < ApplicationRecord
  belongs_to :coupon
  belongs_to :category
end
