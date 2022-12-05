# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :content_page do
    vendor
    position { 1 }
    title { 'MyString' }
    content { 'some content' }
  end
end
