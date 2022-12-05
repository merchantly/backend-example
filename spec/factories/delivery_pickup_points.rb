FactoryBot.define do
  factory :delivery_pickup_point do
    delivery_city { nil }
    title_translations { '' }
    is_active { false }
    details_translations { '' }
  end
end
