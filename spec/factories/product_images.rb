# Read about factories at https://github.com/thoughtbot/factory_girl
# include ActionDispatch::TestProcess
FactoryBot.define do
  factory :product_image do
    # product
    vendor
    image { File.new(Rails.root.join('spec/fixtures/donut_1.png')) }
    # image { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'donut_1.png'), 'image/png') }
  end
end
