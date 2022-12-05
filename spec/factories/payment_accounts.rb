FactoryBot.define do
  factory :payment_account do
    vendor
    card_first_six { 'MyString' }
    card_last_four { 'MyString' }
    card_type { 'MyString' }
    issuer_bank_country { 'MyString' }
    token { 'MyText' }
    card_exp_date { 'MyString' }
  end
end
