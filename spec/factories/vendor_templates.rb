FactoryBot.define do
  factory :vendor_template do
    is_test { false }
    name { 'Пустой магазин' }
    vendor { create :vendor, :payments_and_deliveries_remote }
    image { fixture_file_upload(Rails.root.join('spec/fixtures/images/600x600.jpg'), 'image/jpeg') }
    description { 'Описание' }
    trait :with_precreated_vendors do
      after :create, &:precreate!
    end
  end
end
