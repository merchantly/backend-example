# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :translation do
    vendor
    locale { :ru }
    key { :key }
  end
end
