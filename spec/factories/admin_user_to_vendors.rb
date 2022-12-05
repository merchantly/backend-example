# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :admin_user_to_vendor do
    admin_user { nil }
    vendor { nil }
  end
end
