# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :city do
    sequence :name do |n|
      "Город номер #{n}"
    end
  end
end
