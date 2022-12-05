# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :openbill_category do
    sequence :name do |n|
      n
    end
  end
end
