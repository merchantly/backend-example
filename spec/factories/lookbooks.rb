# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :lookbook do
    vendor   { create :vendor }
    position { 1 }
    title { 'MyString' }
  end
end
