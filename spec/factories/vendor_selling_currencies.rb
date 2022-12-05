# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :vendor_selling_currency do
    vendor { '' }
    currency_iso_code { 'MyString' }
  end
end
