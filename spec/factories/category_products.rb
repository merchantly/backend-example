# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :category_product do
    category { nil }
    product { nil }
    row_order { 1 }
  end
end
