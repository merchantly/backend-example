# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :asset_image do
    vendor
    image { fixture_file_upload(Rails.root.join('spec/fixtures/donut_1.png'), 'image/png') }
    width { 1 }
    height { 1 }
  end
end
