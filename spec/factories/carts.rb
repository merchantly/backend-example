# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :cart do
    vendor
    association :session, factory: :user_session
    coupon_code { nil }

    trait :items do
      transient do
        items_count { 3 }
      end
      after :create do |cart, evaluator|
        cart.items << build_list(:cart_item, evaluator.items_count, cart: cart)
      end
    end

    trait :unorderable_items do
      transient do
        items_count { 3 }
      end
      after :create do |cart, evaluator|
        cart.items << build_list(:cart_item, evaluator.items_count, :unorderable, cart: cart)
      end
    end
  end
end
