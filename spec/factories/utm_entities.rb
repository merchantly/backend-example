# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence :utm do |n|
    "utm#{n}"
  end

  factory :utm_entity do
    utm_source   { generate :utm }
    utm_campaign { generate :utm }
    utm_medium   { generate :utm }
    utm_term     { generate :utm }
    utm_content  { generate :utm }
  end
end
