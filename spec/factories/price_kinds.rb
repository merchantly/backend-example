FactoryBot.define do
  factory :price_kind do
    vendor { create :vendor }

    trait :default do
      title { 'Цена' }
      after(:create) do |price_kind|
        price_kind.vendor.update_column :default_price_kind_id, price_kind.id
      end
    end

    trait :sale do
      title { 'Распродажа' }
      after(:create) do |price_kind|
        price_kind.vendor.update_column :sale_price_kind_id, price_kind.id
      end
    end
  end
end
