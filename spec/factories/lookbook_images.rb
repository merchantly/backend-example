# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :lookbook_image do
    lookbook
    vendor
    image { File.new(Rails.root.join('spec/fixtures/donut_1.png')) }
  end
end
