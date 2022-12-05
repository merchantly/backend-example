# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence(:category_name) { |n| "name#{n}" }
  factory :category do
    vendor
    title { generate :category_name }

    trait :children do
      after :create do |category|
        category.children.create title: generate(:category_name)
        category.children.create title: generate(:category_name)
      end
    end

    trait :products do
      after :create do |category, _evaluator|
        create :product, category_ids: [category.id], vendor_id: category.vendor.id
      end
    end
  end
end
