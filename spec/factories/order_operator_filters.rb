FactoryBot.define do
  factory :order_operator_filter do
    vendor
    name { 'MyString' }
    color_hex { '#ffffff' }
    workflow_state_id { nil }
    has_reserved_items { nil }
    delivery_state { nil }
    payment_state { nil }
    delivery_type_id { nil }
    payment_type_id { nil }
    coupon_id { nil }
  end
end
