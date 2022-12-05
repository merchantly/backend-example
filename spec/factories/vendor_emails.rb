FactoryBot.define do
  factory :vendor_email do
    vendor { nil }
    email { 'MyString' }
    is_active { false }
    last_checkup_result { 'MyText' }
    last_checkup_at { '2017-11-28 08:12:58' }
  end
end
