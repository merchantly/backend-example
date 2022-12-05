# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence(:item_article) { |n| "article#{n}" }
  factory :product_item do
    product
    quantity { nil }
    vendor { product.vendor }
    article { generate :item_article }
    ms_stockstores { generate :item_article }

    trait :ordering do
      quantity { 12 }
      externalcode { generate :uuid }
      ms_stockstores { generate :uuid }
      ms_uuid { generate :uuid }
    end

    trait :property do
      after :create do |product_item, _evaluator|
        prop = create :property_string, vendor: product_item.vendor
        product_item.update custom_attributes: [prop.build_attribute_by_value('some')]
      end
    end

    trait :property_file do
      after :create do |product_item, _evaluator|
        prop = create :property_file, vendor: product_item.vendor
        file = File.new(Rails.root.join('spec/fixtures/donut_1.png'))
        product_item.update custom_attributes: [prop.build_attribute_by_value(file)]
      end
    end

    trait :property_dictionary do
      after :create do |product_item, _evaluator|
        prop = create :property_dictionary_with_entities, vendor: product_item.vendor
        product_item.update_column :data, prop.id => prop.entities.first.id
      end
    end
  end
end
