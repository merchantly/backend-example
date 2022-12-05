# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :phone_confirmation do
    phone { generate :phone }
    operator

    trait :confirmed do
      is_confirmed { true }
      confirmed_at { Time.zone.now }
    end
  end
end
