# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :admin_user do
    email { 'test@test.com' }
    password { 'password' }
  end
end
