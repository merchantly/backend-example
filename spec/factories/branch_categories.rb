# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :branch_category do
    CategoryId { 'MyString' }
    CategoryGroup { 'MyString' }
    title { 'MyString' }
  end
end
