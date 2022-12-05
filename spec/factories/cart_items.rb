# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :cart_item do
    cart
    good { create :product, :ordering, vendor_id: cart.vendor_id }
    count { 1 }
    product_price { good.default_product_price }

    trait :unorderable do
      good { create :product, vendor_id: cart.vendor_id }
    end
  end
end
