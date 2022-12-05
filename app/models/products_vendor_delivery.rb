class ProductsVendorDelivery < ApplicationRecord
  belongs_to :product
  belongs_to :vendor_delivery
end
