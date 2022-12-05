# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :order_condition_order do
    order { nil }
    order_condition { nil }
  end
end
