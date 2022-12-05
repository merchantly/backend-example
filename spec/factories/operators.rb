# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence :name do |n|
    "Оператор#{n}"
  end

  sequence :phone do |n|
    "+790000000#{n}"
  end

  sequence :email do |n|
    "email#{n}@email.com"
  end

  trait :with_partner do
    after :build do |operator|
      operator.partner = create :partner, :with_coupon
    end
  end

  factory :operator do
    email { generate :email }
    phone { generate :phone }
    password { 'password' }

    name { generate :name }
    system_subscriptions { SystemMailTemplate::TYPES }

    trait :has_vendor do
      after :create do |operator|
        operator.members.create! vendor: create(:vendor)
      end
    end
  end
end
