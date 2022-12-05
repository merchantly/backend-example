# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence :w1_phone do |n|
    "+790000000#{n}"
  end
  factory :vendor_walletone do
    vendor
    branch_category_id { 1 }
    title { 'MyString' }
    currency_id { 643 }
    legal_country { 'MyString' }
    legal_title { 'MyString' }
    legal_tax_number { 'MyString' }
    legal_address { 'MyString' }
    legal_reg_number { 'MyString' }
    first_name { 'MyString' }
    middle_name { 'MyString' }
    last_name { 'MyString' }
    phone { generate :w1_phone }
    email { generate :email }
    merchant_sign_key { 'MyString' }
    merchant_token { 'MyString' }
    owner_user_id { 'MyString' }
    state { VendorWalletone::STATE_APPROVED }

    sequence :merchant_id do |n|
      "w1#{n}"
    end

    trait :not_approved do
      merchant_sign_key { nil }
      merchant_token { nil }
      owner_user_id { nil }
      merchant_id { nil }
      state { VendorWalletone::STATE_NOT_APPROVED }
    end
  end
end
