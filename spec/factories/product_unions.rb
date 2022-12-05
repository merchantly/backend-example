FactoryBot.define do
  sequence(:product_union_title) { |n| "product_union_title#{n}" }

  factory :product_union do
    title    { generate :product_union_title }
    vendor   { create :vendor }

    trait :products do
      transient do
        items_count { 3 }
      end
      after :create do |union, evaluator|
        union.products << build_list(:product, evaluator.items_count, vendor: union.vendor)
      end
    end
  end
end
