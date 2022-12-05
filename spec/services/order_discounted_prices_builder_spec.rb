require 'rails_helper'

describe OrderDiscountedPricesBuilder  do
  subject { described_class.new(order: order).perform }

  let(:vendor)        { create :vendor }
  let(:package_good)  { create :product, vendor: vendor, price: package_price }
  let(:delivery_type) { create :vendor_delivery, vendor: vendor, price: delivery_price }
  let(:coupon)        { create :coupon, vendor: vendor, discount: discount_percents }
  let(:order) do
    order = build :order,
                  vendor: vendor,
                  delivery_type: delivery_type,
                  package_good: package_good,
                  package_count: package_count,
                  coupon: coupon

    items_map.each do |i|
      good = create :product, vendor: vendor, price: i[:price]
      order.items.build(
        good: good,
        price: good.price,
        count: i[:count],
        title: good.title,
        total_sale_amount: Money.zero
      )
    end
    order.save!
    order
  end

  let(:items_price) { items_map.sum { |i| i[:price] * i[:count] } }

  describe do
    let(:discount_percents) { 15 }

    let(:package_count)  { 1 }
    let(:package_price)  { 10.to_money }
    let(:delivery_price) { 300.to_money }
    let(:items_map) do
      [
        { price: 250.to_money, count: 1 },
        { price: 650.to_money, count: 1 },
        { price: 280.to_money, count: 2 },
        { price: 450.to_money, count: 1 }
      ]
    end

    specify 'валидация заказа' do
      expect(package_good.price).to eq package_price
      expect(order.delivery_price).to eq delivery_price
      expect(order.package_price).to eq package_price
      expect(order.products_price).to eq items_price
      total = ((250 * 1) + (650 * 1) + (280 * 2) + (450 * 1)) * (100 - discount_percents)
      expect(order.total_price).to eq (total.to_money / 100) + package_price
      expect(order.total_with_delivery_price).to eq order.total_price + delivery_price
    end

    it do
      expect(subject.total_price).to eq order.total_with_delivery_price
    end
  end

  describe do
    let(:discount_percents) { 10 }
    # let(:discount_price) { 479.to_money  }

    let(:package_count)  { 1 }
    let(:package_price)  { 400.to_money }
    let(:delivery_price) { 500.to_money }
    let(:items_map) do
      [
        { price: 300.to_money, count: 5 }, # 1500
        { price: 500.to_money, count: 4 }  # 2000
      ]
    end

    # 1500 + 2000 + 400 + 500

    # self.products_price = calculated_products_price
    # self.package_price  = calculated_package_price
    # self.total_price    = calculated_total_price
    # self.delivery_price = calculated_delivery_price
    # self.free_delivery_threshold = calculated_free_delivery_threshold
    # self.total_with_delivery_price = total_price + delivery_price

    specify 'валидация заказа' do
      expect(package_good.price).to eq package_price
      expect(order.delivery_price).to eq delivery_price
      expect(order.package_price).to eq package_price
      expect(order.products_price).to eq items_price
      total = ((300 * 5) + (500 * 4)) * (100 - discount_percents)
      expect(order.total_price).to eq (total.to_money / 100) + package_price
      expect(order.total_with_delivery_price).to eq order.total_price + delivery_price
    end

    it do
      expect(subject.total_price).to eq order.total_with_delivery_price
    end
  end

  describe do
    let(:discount_percents) { 15 }

    let(:package_count)  { 1 }
    let(:package_price)  { 400.to_money }
    let(:delivery_price) { 500.to_money }
    let(:items_map) do
      [
        { price: 250.to_money, count: 2 },
        { price: 390.to_money, count: 1 },
        { price: 6500.to_money, count: 3 },
        { price: 330.to_money, count: 1 }
      ]
    end

    specify 'Цена позиции не уходит в минус' do
      order_prices_items = order.order_prices.items
      expect(order_prices_items.map(&:total_price).reduce(:+)).to eq(order.total_price - package_price)

      order_prices_items.each do |order_prices_item|
        expect(order_prices_item.price).to be > 0
      end
    end
  end

  describe do
    let(:discount_price) { 9999.to_money }
    let(:coupon) { create :coupon, vendor: vendor, discount_type: :fixed, discount: discount_price.to_f }

    let(:package_count)  { 1 }
    let(:package_price)  { 400.to_money }
    let(:delivery_price) { 500.to_money }
    let(:items_map) do
      [
        { price: 300.to_money, count: 5 }, # 1500
        { price: 500.to_money, count: 4 }  # 2000
      ]
    end

    it 'Скидка больше суммы заказа' do
      expect(subject.total_price).to eq order.total_with_delivery_price
    end
  end

  describe do
    let(:discount_percents) { 15 }

    let(:package_count)  { 1 }
    let(:package_price)  { 1.to_money }
    let(:delivery_price) { 400.to_money }
    let(:items_map) do
      [
        { price: 99.to_money, count: 1 },
        { price: 780.to_money, count: 1 },
        { price: 169.to_money, count: 2 },
        { price: 339.to_money, count: 4 },
        { price: 199.to_money, count: 1 },
        { price: 120.to_money, count: 1 },
        { price: 1350.to_money, count: 1 },
        { price: 590.to_money, count: 3 },
        { price: 590.to_money, count: 3 },
        { price: 590.to_money, count: 3 },
        { price: 49.to_money, count: 2 },
        { price: 390.to_money, count: 1 },
        { price: 299.to_money, count: 1 },
        { price: 299.to_money, count: 1 },
        { price: 299.to_money, count: 1 },
        { price: 349.to_money, count: 1 },
        { price: 299.to_money, count: 1 },
        { price: 179.to_money, count: 1 },
        { price: 249.to_money, count: 1 },
        { price: 589.to_money, count: 1 },
        { price: 490.to_money, count: 1 }
      ]
    end

    it 'Итого совпало' do
      expect(subject.total_price).to eq order.total_with_delivery_price
    end
  end
end
