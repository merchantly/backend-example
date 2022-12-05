FactoryBot.define do
  factory :vendor_exchange_rate do
    vendor { nil }
    from { 'MyString' }
    to { 'MyString' }
    rate { '' }
    comment { 'MyString' }
  end
end
