# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryBot.define do
  sequence(:product_slug_path) { |n| "/product-path#{n}" }
  sequence(:product_title) { |n| "product_title#{n}" }
  sequence(:description) { |n| "Описание #{n}" }

  sequence(:ms_uuid) { |n| "ms_uuid#{n}" }
  sequence(:externalcode) { |n| "externalcode#{n}" }
  sequence(:ms_stockstores) { |n| "ms_stockstores#{n}" }

  factory :product do
    title    { generate :product_title }
    vendor   { create :vendor }
    weight_of_price { 1 }
    price { 10.to_money vendor.try(:default_currency).try(:iso_code) }

    after :create do |product|
      if IntegrationModules.enable?(:ecr)
        product.nomenclature.update! purchase_price: 1.to_money(product.vendor.try(:default_currency).try(:iso_code)), vat: 10
      end
    end

    trait :with_nomenclature do
      nomenclature { create :nomenclature, vendor: vendor }
    end

    trait :no_categories do
      category_ids { nil }
    end

    trait :selling_by_weight do
      selling_by_weight { true }
    end

    trait :slug do
      after :create do |product, _evaluator|
        product.create_slug! path: generate(:product_slug_path)
      end
    end

    trait :ordering do
      ms_uuid { generate :ms_uuid }
      externalcode { generate :externalcode }
      ms_stockstores { generate :ms_stockstores }
      archived_at { nil }
      is_published { true }
      quantity { 1 }
    end

    trait :published do
      is_published { true }
    end

    trait :not_published do
      is_published { false }
      is_manual_published { false }
    end

    trait :archived do
      archived_at { 1.day.ago }
    end

    trait :property do
      after :create do |product, _evaluator|
        prop = create :property_string, vendor: product.vendor
        product.update custom_attributes: [prop.build_attribute_by_value('some')]
      end
    end

    trait :property_file do
      after :create do |product, _evaluator|
        prop = create :property_file, vendor: product.vendor
        file = File.new(Rails.root.join('spec/fixtures/donut_1.png'))
        product.update custom_attributes: [prop.build_attribute_by_value(file)]
      end
    end

    trait :property_dictionary do
      after :create do |product, _evaluator|
        prop = create :property_dictionary_with_entities, vendor: product.vendor
        product.update_column :data, prop.id => prop.entities.first.id
      end
    end

    trait :items do
      transient do
        items_count { 3 }
        items_ms_uuid { nil }
      end
      after :create do |product, evaluator|
        product.items << build_list(:product_item, evaluator.items_count, product: product, ms_uuid: evaluator.items_ms_uuid)
      end
    end

    trait :images do
      transient do
        items_count { 3 }
      end
      after :create do |product, evaluator|
        product.update_column(:image_ids, (1..evaluator.items_count).map { create(:product_image, product_id: product.id, vendor_id: product.vendor_id).id })
      end
    end

    trait :order_items do
      after :create do |product, _evaluator|
        product.order_items << build_list(:order_item, 3, good: product)
      end
    end
  end
end
