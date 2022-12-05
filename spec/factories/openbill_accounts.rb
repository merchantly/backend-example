# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :openbill_account do
    association :category, factory: :openbill_category
    amount_currency { 'RUB' }
    sequence :details do |n|
      n
    end
    sequence :key do |n|
      n
    end
  end
end
