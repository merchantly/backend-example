# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :tariff_order do
    from_orders_count { 0 }
    to_orders_count { 999_999_999 }
    per_order_price_cents { 100 }
    per_order_price_currency { 'RUB' }
    per_month_price_cents { 100 }
    per_month_price_currency { 'RUB' }
  end
end
