# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :account do
    vendor
    card_first_six { 'MyString' }
    card_last_four { 'MyString' }
    card_type { 'MyString' }
    issuer_bank_country { 'MyString' }
    token { 'MyText' }
    card_exp_date { 'MyString' }
  end
end
