FactoryBot.define do
  factory :vendor_analytics_session do
    vendor { nil }
    session_id { 'MyString' }
    source { nil }
  end
end
