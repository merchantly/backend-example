# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :subscription_email do
    vendor
    sequence :email do |n|
      "person#{n}@example.com"
    end
  end
end
