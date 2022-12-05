# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :client_phone do
    client
    phone { generate :phone }
    confirmed { false }
  end
end
