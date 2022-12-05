class VendorSellingCurrency < ApplicationRecord
  belongs_to :vendor, counter_cache: :selling_currencies_count
end
