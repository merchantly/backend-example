require 'rails_helper'

describe Discounter::Percent do
  subject do
    described_class.new(coupon: coupon, items: items, package_good: package_good, package_count: 1).perform
  end

  let!(:vendor) { create :vendor }
  let(:discount) { 10 }

  let(:item1_price) { 1000.to_money vendor.default_currency }
  let(:item2_price) { 2000.to_money vendor.default_currency }
  let(:items_price) { item1_price + item2_price }
  let(:items) do
    [
      double(total_price: item1_price, vat_percent: 0, vat_amount: vendor.zero_money, product: nil),
      double(total_price: item2_price, vat_percent: 0, vat_amount: vendor.zero_money, product: nil)
    ]
  end
  let(:total_price) { items_price + package_price }

  let(:package_price) { 500.to_money vendor.default_currency }
  let(:package_good)  { create :product, vendor: vendor, price: package_price }

  describe 'бесплатная доставка с условными купонами' do
    let(:vendor) { create :vendor, :delivery }
    let(:cart) { create :cart, vendor: vendor }
    let(:category) { create :category, vendor: vendor }
    let(:product) { create :product, :ordering, vendor: vendor, category_ids: [category.id] }
    let!(:cart_item) { create :cart_item, good: product, cart: cart }
    let(:items) { [cart_item] }
    let(:coupon) { create :coupon_free_delivery, discount: 0, vendor: vendor, product_ids: [product.id], use_products_behavior: products_behavior }

    context 'заказываем товар подходящий под условие' do
      let(:products_behavior) { Coupon::USE_BEHAVIOR_INCLUDE }

      it 'доставка бесплатная' do
        expect(subject.free_delivery).to be_truthy
      end
    end

    context 'заказываем товар не подходящий под условие' do
      let(:products_behavior) { Coupon::USE_BEHAVIOR_EXCLUDE }

      it 'доставка платная' do
        expect(subject.free_delivery).to be_falsey
      end
    end

    context 'заказываем два товара, один из которых подходит под условие' do
      let(:products_behavior) { Coupon::USE_BEHAVIOR_INCLUDE }
      let(:product2) { create :product, :ordering, vendor: vendor, category_ids: [category.id] }
      let!(:cart_item2) { create :cart_item, good: product2, cart: cart }

      it 'доставка бесплатная' do
        expect(subject.free_delivery).to be_truthy
      end
    end
  end

  context 'скидка без упаковки' do
    let(:coupon) { create :coupon, discount_type: :percent, is_discounting_package: false, discount: discount, vendor: vendor }
    let(:total_discounted) { (items_price * (100 - discount) / 100) + package_price }

    let(:discount_price) { items_price + package_price - total_discounted }

    it { expect(subject).to be_a Discounting }
    it { expect(subject.discount_price).to eq discount_price }
    it { expect(subject.discount).to eq discount }
    it { expect(subject.free_delivery).to eq false }
    it { expect(subject.total_discounted).to eq total_discounted }
  end

  context 'скидка с упаковкой и бесплатной доставкой' do
    let(:coupon) { create :coupon_free_delivery, discount_type: :percent, is_discounting_package: true, discount: discount, vendor: vendor }
    let(:total_discounted) { total_price * (100 - discount) / 100 }

    let(:discount_price) { total_price - total_discounted }

    it { expect(subject).to be_a Discounting }
    it { expect(subject.discount_price).to eq discount_price }
    it { expect(subject.discount).to eq discount }
    it { expect(subject.free_delivery).to eq true }
    it { expect(subject.total_discounted).to eq total_discounted }
  end

  context 'Купон только для указанных категорий' do
    let(:included_category) { create :category, vendor: vendor }
    let(:categories_behavior) { Coupon::USE_BEHAVIOR_INCLUDE }
    let(:coupon) do
      create :coupon,
             discount_type: :percent,
             discount: discount,
             use_categories_behavior: categories_behavior,
             vendor: vendor,
             category_ids: [included_category.id]
    end

    let(:items) do
      [
        double(total_price: item1_price, product: product1, vat_percent: 0, vat_amount: vendor.zero_money),
        double(total_price: item2_price, product: product2, vat_percent: 0, vat_amount: vendor.zero_money)
      ]
    end

    describe 'оба товара во включаемой категории' do
      let(:product1) { create :product, vendor: vendor, category: included_category }
      let(:product2) { create :product, vendor: vendor, category: included_category }
      let(:discount_price) { (item1_price + item2_price) * discount / 100 }
      let(:total_discounted) { (items_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end

    describe 'один из товаров во включаемой категории' do
      let(:product1) { create :product, vendor: vendor, category: included_category }
      let(:product2) { create :product, vendor: vendor }
      let(:discount_price) { item1_price * discount / 100 }
      let(:total_discounted) { item2_price + (item1_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end

    describe 'ни один из товаров не во включаемой категории' do
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }

      it { expect(subject.discount_price).to eq vendor.zero_money }
      it { expect(subject.discount).to eq 0 }
      it { expect(subject.total_discounted).to eq total_price }
    end
  end

  context 'Купон исключающий товары из указанных категорий' do
    let(:excluded_category) { create :category, vendor: vendor }
    let(:categories_behavior) { Coupon::USE_BEHAVIOR_EXCLUDE }
    let(:coupon) do
      create :coupon,
             discount_type: :percent,
             discount: discount,
             use_categories_behavior: categories_behavior,
             vendor: vendor,
             category_ids: [excluded_category.id]
    end

    let(:discount_price) { total_price - total_discounted }

    let(:items) do
      [
        double(total_price: item1_price, product: product1, vat_percent: 0, vat_amount: vendor.zero_money),
        double(total_price: item2_price, product: product2, vat_percent: 0, vat_amount: vendor.zero_money)
      ]
    end

    describe 'оба товара в исключаемой категории' do
      let(:product1) { create :product, vendor: vendor, category: excluded_category }
      let(:product2) { create :product, vendor: vendor, category: excluded_category }

      it { expect(subject.discount_price).to eq vendor.zero_money }
      it { expect(subject.discount).to eq 0 }
      it { expect(subject.total_discounted).to eq total_price }
    end

    describe 'один товар и он в исключаемой категории' do
      let(:items) { [double(total_price: item1_price, product: product1, vat_percent: 0, vat_amount: vendor.zero_money)] }
      let(:product1) { create :product, vendor: vendor, category: excluded_category }

      it { expect(subject.discount_price).to eq vendor.zero_money }
      it { expect(subject.discount).to eq 0 }
      it { expect(subject.total_discounted).to eq item1_price + package_price }
    end

    describe 'один из товаров в исключаемой категории' do
      let(:product1) { create :product, vendor: vendor, category: excluded_category }
      let(:product2) { create :product, vendor: vendor }
      let(:total_discounted) { item1_price + (item2_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end

    describe 'ни один из товаров не в исключаемой категории' do
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }
      let(:total_discounted) { (items_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end
  end

  context 'Купон только для указанных товаров' do
    let(:products_behavior) { Coupon::USE_BEHAVIOR_INCLUDE }
    let(:coupon) do
      create :coupon,
             discount_type: :percent,
             discount: discount,
             use_products_behavior: products_behavior,
             vendor: vendor,
             product_ids: included_products.map(&:id)
    end

    let(:items) do
      [
        double(total_price: item1_price, product: product1, vat_percent: 0, vat_amount: vendor.zero_money),
        double(total_price: item2_price, product: product2, vat_percent: 0, vat_amount: vendor.zero_money)
      ]
    end

    describe 'оба товара включены' do
      let(:included_products) { [product1, product2] }
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }

      let(:discount_price) { (item1_price + item2_price) * discount / 100 }
      let(:total_discounted) { (items_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end

    describe 'один из товаров включен' do
      let(:included_products) { [product1] }
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }
      let(:discount_price) { item1_price * discount / 100 }
      let(:total_discounted) { item2_price + (item1_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end

    describe 'ни один из товаров не включен' do
      let(:included_products) { [product] }
      let(:product) { create :product, vendor: vendor }
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }

      it { expect(subject.discount_price).to eq vendor.zero_money }
      it { expect(subject.discount).to eq 0 }
      it { expect(subject.total_discounted).to eq total_price }
    end
  end

  context 'Купон только НЕ для исключенных товаров' do
    let(:products_behavior) { Coupon::USE_BEHAVIOR_EXCLUDE }
    let(:coupon) do
      create :coupon,
             discount_type: :percent,
             discount: discount,
             use_products_behavior: products_behavior,
             vendor: vendor,
             product_ids: included_products.map(&:id)
    end

    let(:items) do
      [
        double(total_price: item1_price, product: product1, vat_percent: 0, vat_amount: vendor.zero_money),
        double(total_price: item2_price, product: product2, vat_percent: 0, vat_amount: vendor.zero_money)
      ]
    end

    describe 'оба товара исключены' do
      let(:included_products) { [product1, product2] }
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }

      it { expect(subject.discount_price).to eq vendor.zero_money }
      it { expect(subject.discount).to eq 0 }
      it { expect(subject.total_discounted).to eq total_price }
    end

    describe 'один из товаров исключен' do
      let(:included_products) { [product2] }
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }
      let(:discount_price) { item1_price * discount / 100 }
      let(:total_discounted) { item2_price + (item1_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end

    describe 'ни один из товаров не исключен' do
      let(:included_products) { [product] }
      let(:product) { create :product, vendor: vendor }
      let(:product1) { create :product, vendor: vendor }
      let(:product2) { create :product, vendor: vendor }

      let(:discount_price) { items_price * discount / 100 }
      let(:total_discounted) { (items_price * (100 - discount) / 100) + package_price }

      it { expect(subject.discount_price).to eq discount_price }
      it { expect(subject.discount).to eq coupon.discount }
      it { expect(subject.total_discounted).to eq total_discounted }
    end
  end

  context 'Купоны на объеденения' do
    let(:product_union) { create :product_union, :products, vendor: vendor }
    let(:coupon) do
      create :coupon,
             discount_type: :percent,
             discount: discount,
             use_products_behavior: products_behavior,
             vendor: vendor,
             product_ids: [product_union.id]
    end

    let(:items) do
      [
        double(total_price: item1_price, product: product_union.products.first, vat_percent: 0, vat_amount: vendor.zero_money)
      ]
    end

    let(:discount_price) { item1_price * discount / 100 }

    describe 'Только для указанного объеденения' do
      let(:products_behavior) { Coupon::USE_BEHAVIOR_INCLUDE }

      it { expect(subject.discount_price).to eq discount_price }
    end

    describe 'Не для объеденения' do
      let(:products_behavior) { Coupon::USE_BEHAVIOR_EXCLUDE }

      it { expect(subject.discount_price).to eq vendor.zero_money }
    end
  end

  context 'Vat amount' do
    let!(:vat_percent) { 5 }
    let!(:vat_amount) { VatAmountCalculator.new(vendor).perform(price: item1_price, vat: vat_percent) }
    let(:coupon) { create :coupon, discount_type: :percent, discount: discount, vendor: vendor }

    let(:items) do
      [double(total_price: item1_price, vat_percent: vat_percent, vat_amount: vat_amount, product: nil)]
    end

    before do
      allow(vendor).to receive(:vat_calculation_version).and_return vat_calculation_version
    end

    describe 'v1' do
      let(:vat_calculation_version) { 'v1' }
      let(:total_vat_price) { 45.to_money }

      it do
        expect(subject.total_vat_price).to eq total_vat_price
      end
    end

    describe 'v2' do
      let(:vat_calculation_version) { 'v2' }
      let(:total_vat_price) { 42.86.to_money }

      it { expect(subject.total_vat_price).to eq total_vat_price }
    end
  end
end
