# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :page do
    vendor { nil }
    title { 'MyString' }
    content { 'MyText' }
  end
end
