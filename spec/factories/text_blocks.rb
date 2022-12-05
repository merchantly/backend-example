# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :text_block do
    product
    title { 'MyString' }
    content { 'MyText<b style="color:red">bold</b>' }
    vendor
  end
end
