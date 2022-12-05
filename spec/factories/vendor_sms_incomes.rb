FactoryBot.define do
  factory :vendor_sms_income do
    vendor
    count { 1 }
    comment { 'без комментариев ;)' }
  end
end
