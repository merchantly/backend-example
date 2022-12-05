# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :favicon_file do
    vendor
    image { fixture_file_upload('donut_1.png', 'image/png') }
    title { 'MyString' }
  end
end
