class CategoriesVendorDelivery < ApplicationRecord
  belongs_to :category
  belongs_to :vendor_delivery
end
