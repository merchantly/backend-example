# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :blog_post do
    vendor
    title { 'MyString' }
    content { 'MyText' }
    short_text { 'MyText' }
    h1 { 'MyText' }
    meta_keywords { 'MyText' }
    meta_description { 'MyText' }
    meta_title { 'MyText' }
  end
end
