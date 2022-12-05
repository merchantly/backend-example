FactoryBot.define do
  factory :vendor_rfm do
    vendor { nil }
    count { 1 }
    max_orders_count { 1 }
    max_total_orders_price { Money.new(1) }
    r { 1 }
    f { 1 }
    m { 1 }
  end
end
