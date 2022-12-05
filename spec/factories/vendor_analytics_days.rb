# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :vendor_analytics_day do
    vendor { nil }
    date { '2017-01-24' }
    orders_count { 1 }
    carts_count { 1 }
    users_count { 1 }
    views_count { 1 }
  end
end
