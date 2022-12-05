# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :vendor_product_analytics_day do
    vendor { nil }
    product { nil }
    orders_count { 1 }
    carts_count { 1 }
    views_count { 1 }
  end
end
