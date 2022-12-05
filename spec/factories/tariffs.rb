FactoryBot.define do
  factory :tariff do
    title { 'tariff' }

    can_change { true }
    is_show_in_choose { true }
    can_send_sms_with_negative_balance { true }
    sms_price_cents { 200 }
    sms_price_currency { 'RUB' }

    month_price_cents { 490_00 }
    month_price_currency { 'RUB' }

    link_app_disable_price_cents { 1_000_00 }
    link_app_disable_price_currency { 'RUB' }
  end
end
