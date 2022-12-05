FactoryBot.define do
  factory :vendor_analytics_visitor do
    vendor { nil }
    session_id { nil }
    user_agent { 'MyText' }
    referer { 'MyString' }
    remote_ip { 'MyString' }
    source { nil }
  end
end
