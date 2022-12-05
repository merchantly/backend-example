FactoryBot.define do
  factory :vendor_order_field do
    vendor
    title { generate :product_title }
  end
end
