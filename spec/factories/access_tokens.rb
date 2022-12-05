# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :access_token do
    vendor
    operator
  end
end
