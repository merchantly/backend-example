# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :operator_registration_form do
    sequence :name do |n|
      "Оператор#{n}"
    end
    sequence :email do |n|
      "email#{n}@email.com"
    end
    sequence :password do |n|
      "pass#{n}"
    end
  end
end
