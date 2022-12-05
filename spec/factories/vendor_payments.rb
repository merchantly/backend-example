# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence :payment_title do |n|
    "Оплата #{n}"
  end

  factory :vendor_payment do
    vendor
    title { generate :payment_title }
    description { 'MyText' }
    payment_agent_type { 'OrderPaymentDirect' }
    vendor_deliveries { vendor.vendor_deliveries.reload }
    cashier { create :cashier, vendor: vendor }
  end

  trait :direct do
    payment_agent_type { 'OrderPaymentDirect' }
    canceling_timeout_minutes { 0 }
  end

  trait :custom do
    payment_agent_type { 'OrderPaymentDirect' }
    content { 'Удачно оформили заказ {{ order.public_id }} на сумму {{ order.total_with_delivery_price | humanized_money_with_symbol }}' }
  end

  trait :w1 do
    payment_agent_type { 'OrderPaymentW1' }
    canceling_timeout_minutes { 1.hour / 60 }
  end

  trait :pay_pal do
    payment_agent_type { 'OrderPaymentPayPal' }
    canceling_timeout_minutes { 1.hour / 60 }
  end

  trait :yandex_kassa do
    payment_agent_type { 'OrderPaymentYandexKassa' }
    canceling_timeout_minutes { 1.hour / 60 }
  end

  trait :rbk_money do
    payment_agent_type { 'OrderPaymentRbkMoney' }
  end
end
