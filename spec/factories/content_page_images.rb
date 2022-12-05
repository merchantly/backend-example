# Подключаем fixture_upload
include ActionDispatch::TestProcess

FactoryBot.define do
  factory :content_page_image do
    content_page
    vendor
    image { fixture_file_upload(Rails.root.join('spec/fixtures/donut_1.png'), 'image/png') }
  end
end
