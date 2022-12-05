# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence(:de_name) { |n| "dictionary_entity#{n}" }
  sequence(:de_uuid) { |n| "uuid#{n}" }

  factory :dictionary_entity do
    dictionary
    vendor { dictionary.vendor }
    title { generate :de_name }
    ms_uuid { generate :de_uuid }
    stock_synced_at { '2014-11-27 10:01:17' }
  end
end
