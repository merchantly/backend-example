# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :payment_to_delivery do
    payment { nil }
    delivery { nil }
  end
end
