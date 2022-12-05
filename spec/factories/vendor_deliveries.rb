# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence :delivery_title do |n|
    "Доставка #{n}"
  end

  factory :vendor_delivery do
    vendor
    position { 1 }
    title { generate :delivery_title }
    description { 'MyText' }
    login { 'login' }
    password { '123' }
    price_cents { 1000 }
    delivery_agent_type { 'OrderDeliveryOther' }
    vendor_payments { vendor.vendor_payments.reload }
  end

  trait :other do
    delivery_agent_type { 'OrderDeliveryOther' }
    price_cents { 0 }
  end

  trait :pickup do
    delivery_agent_type { 'OrderDeliveryPickup' }
    price_cents { 0 }
  end

  trait :cse do
    delivery_agent_type { 'OrderDeliveryCSE' }
  end

  trait :redexpress do
    delivery_agent_type { 'OrderDeliveryRedexpress' }
  end

  trait :ems do
    delivery_agent_type { 'OrderDeliveryEMS' }
  end
end
