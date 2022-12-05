FactoryBot.define do
  factory :product_price do
    subject { create :product }

    trait :default do
      price_kind { vendor.default_price_kind }
    end

    trait :sale do
      price_kind { vendor.sale_price_kind }
    end
  end
end
