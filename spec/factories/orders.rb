# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :order do
    vendor

    payment_type  { create :vendor_payment, :w1, vendor: vendor }
    delivery_type { create :vendor_delivery, :cse, vendor: vendor }
    client        { create :client, vendor: vendor }

    # city
    city_title    { 'Москва' }
    phone         { '+79033891228' }
    name          { 'MyString' }
    comment       { 'MyString' }
    address       { 'Адрес' }
    email         { 'client@test.ru' }
    uuid          { SecureRandom.uuid }

    products_price            { vendor.zero_money }
    total_price               { vendor.zero_money } # Money.new(100) }
    delivery_price            { vendor.zero_money }
    total_with_delivery_price { vendor.zero_money }
    currency_iso_code         { vendor.currency_iso_code }
    discount_price            { vendor.zero_money }
    discount                  { 0 }

    total_sale_amount { vendor.zero_money }

    trait :items do
      transient do
        items_count { 3 }
      end
      after :create do |order, evaluator|
        order.items << build_list(:order_item, evaluator.items_count)
      end
    end

    trait :delivery_pickup do
      payment_type { create :vendor_payment, :direct, vendor: vendor }
      delivery_type { create :vendor_delivery, :pickup, vendor: vendor }
    end

    trait :delivery_redexpress do
      delivery_type { create :vendor_delivery, :redexpress, vendor: vendor }
    end

    trait :delivery_cse do
      delivery_type { create :vendor_delivery, :cse, vendor: vendor }
    end

    trait :delivery_ems do
      delivery_type { create :vendor_delivery, :ems, vendor: vendor }
    end

    trait :payment_w1 do
      payment_type { create :vendor_payment, :w1, vendor: vendor }
    end

    trait :payment_pay_pal do
      payment_type { create :vendor_payment, :pay_pal, vendor: vendor }
    end

    trait :payment_yandex_kassa do
      payment_type { create :vendor_payment, :yandex_kassa, vendor: vendor }
    end

    trait :payment_rbk_money do
      payment_type { create :vendor_payment, :rbk_money, vendor: vendor }
    end

    trait :payment_direct do
      payment_type { create :vendor_payment, :direct, vendor: vendor }
    end
  end
end
