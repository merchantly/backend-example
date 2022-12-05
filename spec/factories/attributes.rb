# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence(:attribute_value) { |n| "value#{n}" }

  factory :attribute_string do
    property { create :property_string }
    value    { generate :attribute_value }
  end

  factory :attribute_dictionary do
    vendor { create :vendor }
    after(:build) do |a, _evaluator|
      dictionary = create :dictionary, vendor: a.vendor
      entity = create :dictionary_entity, dictionary: dictionary, vendor: a.vendor
      a.property = create :property_dictionary, dictionary: dictionary, vendor: a.vendor
      a.dictionary_entity_id = entity.id
    end
  end
end
