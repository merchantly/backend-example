# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :property do
    sequence :title do |n|
      "Атрибут #{n}"
    end
    sequence :key do |n|
      "attr_#{n}"
    end
    vendor
  end

  factory :property_string, parent: :property, class: 'PropertyString'
  factory :property_file, parent: :property, class: 'PropertyFile'

  factory :property_dictionary, parent: :property, class: 'PropertyDictionary' do
    dictionary
  end

  factory :property_dictionary_with_entities, parent: :property, class: 'PropertyDictionary' do
    dictionary { create :dictionary, :entities }
  end
end
