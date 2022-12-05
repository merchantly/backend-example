FactoryBot.define do
  factory :vendor_analytics_source do
    vendor { nil }
    utm_source { 'MyString' }
    utm_campaign { 'MyString' }
    utm_medium { 'MyString' }
    utm_term { 'MyString' }
    utm_content { 'MyString' }
    referer { 'MyText' }
    params { '' }
  end
end
