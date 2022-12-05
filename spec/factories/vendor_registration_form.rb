# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :vendor_registration_form do
    sequence :vendor_name do |n|
      "Компания#{n}"
    end
    sequence :operator_name do |n|
      "Оператор#{n}"
    end
    domain_zone { 'kiiiosk.store' }
    sequence :email do |n|
      "email#{n}@email.com"
    end
    sequence :phone do |_n|
      Array.new(11) { |_t| rand(1..9) }.join
    end
  end
end
