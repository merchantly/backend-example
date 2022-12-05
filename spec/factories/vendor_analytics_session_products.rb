FactoryBot.define do
  factory :vendor_analytics_session_product do
    session_id { 'MyString' }
    date { '2017-10-05' }
    time { '2017-10-05 21:42:36' }
    product { nil }
    views_count { 1 }
    carts_count { 1 }
    orders_count { 1 }
  end
end
