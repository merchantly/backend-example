require 'rails_helper'

RSpec.describe Cart, type: :model do
  let_it_be(:vendor) { create :vendor, :with_package_category }
  subject { cart }

  let(:cart) { create :cart, :items, vendor_id: vendor.id }

  it do
    expect(cart.items.reload).to have(3).items
  end

  it 'проверяем factory. Все товары покупаемые' do
    expect(cart.items.reload.select { |i| i.good.has_ordering_goods }).to have(3).items
    expect(cart.items.reload.map { |i| i.good.vendor_id }.uniq).to eq [vendor.id]
  end

  describe '#update_package' do
    let_it_be(:package) { create :product, vendor: vendor, category_ids: [vendor.package_category.id] }

    context 'add package' do
      before { subject.update package_good_global_id: package.global_id }

      it 'adds package good' do
        expect(cart.reload.package_good.id).to eq package.id
      end
    end
  end

  describe 'products include discount' do
    subject { create :cart, :items, vendor_id: vendor.id }

    let(:coupon) { create :coupon_single, vendor: vendor, product_ids: [subject.items.first.product.id], use_products_behavior: Coupon::USE_BEHAVIOR_INCLUDE }

    before do
      subject.update_attribute :coupon_code, coupon.code
    end

    it do
      expect(subject.total_discounted).to eq Money.new(28_00, :rub)
    end
  end

  describe 'products exclude discount' do
    # Каждый товар по 10 рублей. Сумма 30.
    subject { create :cart, :items, vendor_id: vendor.id }
    # Скидка в 20%.
    # Сумма со скидкой должна получиться
    # 1. 10 - 20% = 8
    # 2. 10 - 20% = 8
    # 3. 10 без скидки = 10
    # Итого: 26

    let(:coupon) do
      create(
        :coupon_single,
        vendor: vendor,
        product_ids: [subject.items.first.product.id],
        use_products_behavior: Coupon::USE_BEHAVIOR_EXCLUDE
      )
    end

    before do
      subject.update_attribute :coupon_code, coupon.code
    end

    it do
      expect(subject.total_discounted).to eq 26.to_money
    end
  end

  describe 'скидка для категорий' do
    context 'назначена для родительской категории' do
      let(:parent_category) { create :category, vendor: vendor }
      let(:child_category) { create :category, vendor: vendor, parent: parent_category }
      let(:product) { create :product, :ordering, vendor: vendor, category_ids: [child_category.id] }
      let(:coupon) { create :coupon_single, vendor: vendor, category_ids: [parent_category.id], use_categories_behavior: Coupon::USE_BEHAVIOR_INCLUDE }
      let!(:cart_item) { create :cart_item, good: product, cart: cart }

      before do
        subject.update_attribute :coupon_code, coupon.code
      end

      it do
        expect(subject.total_discounted).to eq Money.new(38_00, :rub)
      end
    end
  end

  context 'clean' do
    before do
      subject.clean!
    end

    it do
      expect(subject.items).to be_empty
    end

    it do
      expect(subject.items_amount).to eq 0
    end

    it do
      expect(subject.total_price.to_f).to eq 0
    end
  end

  context do
    let_it_be(:vendor)  { create :vendor, :with_package_category }
    let_it_be(:package) { create :product, vendor: vendor, category_ids: [vendor.package_category.id] }
    let_it_be(:good)    { create :product, vendor: vendor }
    let_it_be(:cart)    { create :cart, vendor: vendor }

    subject { cart }

    it 'default' do
      expect(cart.items.count).to eq 0
    end

    context 'add_good' do
      it do
        expect(subject.add_good(good, product_price: good.default_product_price)).to be_truthy
        expect(cart.items.count).to eq 1
      end
    end

    context 'remove_good' do
      before do
        subject.add_good good, product_price: good.default_product_price
      end

      it do
        subject.remove_good good
        expect(cart.items.count).to eq 0
      end
    end

    context 'update_good' do
      context 'update if exists' do
        before do
          subject.add_good good, product_price: good.default_product_price
        end

        it do
          subject.update_good good: good, count: 123, product_price: good.default_product_price
          expect(cart.items.by_good(good).first.count).to eq 123
        end
      end

      context 'create when not exists' do
        it do
          subject.update_good good: good, count: 123, product_price: good.default_product_price
          expect(cart.items.by_good(good).first.count).to eq 123
        end
      end
    end
  end
end
