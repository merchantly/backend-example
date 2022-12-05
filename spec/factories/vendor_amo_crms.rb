# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :vendor_amo_crm do
    vendor { nil }
    login { 'MyString' }
    password { 'MyString' }
    is_active { false }
    last_error { 'MyText' }
  end
end
