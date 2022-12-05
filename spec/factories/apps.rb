# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :app do
    vendor { nil }
    kind { 'MyString' }
    app_file { 'MyString' }
  end
end
