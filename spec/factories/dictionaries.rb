# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :dictionary do
    vendor
    title { 'MyString' }
    ms_uuid { generate :uuid }
    stock_synced_at { '2014-11-27 09:57:30' }

    trait :entities do
      transient do
        entities_count { 3 }
      end
      after :create do |dictionary, evaluator|
        dictionary.entities << build_list(:dictionary_entity, evaluator.entities_count)
      end
    end
  end
end
