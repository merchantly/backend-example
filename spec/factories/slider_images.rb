# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :slider_image do
    vendor
    image { fixture_file_upload(Rails.root.join('spec/fixtures/donut_1.png'), 'image/png') }
    is_active { true }
  end
end
