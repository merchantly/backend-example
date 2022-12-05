# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :top_banner do
    vendor
    content { 'MyText' }
    link_url { 'http://asdf.ru' }
  end
end
