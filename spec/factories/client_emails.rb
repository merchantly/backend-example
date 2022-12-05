# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :client_email do
    client
    email { generate :email }
    confirmed { false }
  end
end
