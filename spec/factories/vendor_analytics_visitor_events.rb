FactoryBot.define do
  factory :vendor_analytics_visitor_event do
    vendor { nil }
    visitor { nil }
    event { 1 }
  end
end
