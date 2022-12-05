require 'rails_helper'

RSpec.describe Product, type: :model do
  let!(:product) { create :product }
  let!(:image) { build :product_image }

  specify do
    expect(product.ordering_as_product_only?).to be true
  end

  describe '#goods' do
    it { expect(product.goods).to have(1).item }
    it { expect(product.goods.first).to eq product }

    # Для того чтобы не показываться в вариантах товаров в пубичной части
    # https://www.pivotaltracker.com/story/show/94678338
    context 'устанавливаем минимальную цены из всех вариантов в sort_actual_price' do
      let!(:product_item) { create :product_item, :ordering, product: product, price: price }
      let!(:second_item) { create :product_item, :ordering, product: product, price: second_price }
      let!(:price) { Money.new(100) }
      let!(:second_price) { Money.new(200) }

      it do
        expect(product.sort_actual_price).to eq price
        expect(product.goods).to have(2).item
      end
    end

    context 'меняем минимальную цену у варианта' do
      let!(:product_item) { create :product_item, :ordering, product: product, price: price }
      let!(:second_item) { create :product_item, :ordering, product: product, price: second_price }
      let!(:price) { Money.new(100) }
      let!(:second_price) { Money.new(200) }
      let!(:minimal_price) { Money.new(50) }

      it do
        second_item.update(price: minimal_price)
        expect(product.sort_actual_price).to eq minimal_price
        expect(product.goods).to have(2).item
      end
    end

    context 'если у товара есть продаваемые варианты, он продается этими вариатнами' do
      let!(:product_item) { create :product_item, :ordering, product: product }

      it do
        expect(product.goods.first).to eq product_item
        expect(product).not_to be_ordering_as_product_only
        expect(product.goods).to have(1).item
      end
    end

    context 'у товара много вариантов, но он сам как default не отдается в goods' do
      let!(:product_item_default)   { create :product_item, product: product, is_default: true }
      let!(:product_item_ordering)  { create :product_item, :ordering, product: product }

      it do
        expect(product).not_to be_ordering_as_product_only
        expect(product.goods).to have(1).item
        expect(product.goods.first).to eq product_item_ordering
      end
    end

    context 'у товара много вариантов, он они все в архиве и он сам продается в виде default product item' do
      let!(:product_item_archived) { create :product_item, :ordering, product: product, archived_at: Time.zone.now }
      let!(:product_item_default) { create :product_item, :ordering, product: product, is_default: true }

      it do
        expect(product).not_to be_ordering_as_product_only
        expect(product.goods).to have(1).item
        expect(product.goods.first).to eq product_item_default
      end
    end
  end

  context 'меняем sort_actual_price' do
    let!(:product) { create :product, price: price, sale_price: sale_price }
    let!(:price) { Money.new(100) }
    let!(:sale_price) { Money.new(10) }
    let!(:new_price) { Money.new(2000) }

    it 'если изменился is_sale' do
      product.update(is_sale: true)

      expect(product.sort_actual_price).to eq sale_price
    end

    it 'если изменилась цена через update' do
      product.update(price: new_price)

      expect(product.sort_actual_price).to eq new_price
    end
  end

  context 'товар должен создаваться через вендора' do
    let(:vendor) { create :vendor }
    let(:product) { vendor.products.create! title: 'test', price: Money.new(123, vendor.default_currency) }

    it do
      expect(product).to be_persisted
    end
  end

  describe 'продукт с модификациями' do
    let(:product) { create :product, :items }

    it { expect(product.ordering_as_product_only?).to be false }
  end

  describe 'продукт с картинками' do
    let!(:product) { create :product, :images, images_count: 3 }

    it 'по-умолчанию factory делает валидный продукт с которым можно работать' do
      expect(product.persisted?).to be true
      expect(product.valid?).to be true
    end
  end

  describe 'цена продукта создается через assign_attibutes' do
    let(:vendor) { create :vendor }
    let!(:product) { create :product, vendor: vendor, product_prices_attributes: { '1541677132114': { price_kind_id: vendor.default_price_kind_id, price: 900, _destroy: false } } }

    it do
      expect(product.persisted?).to be true
      expect(product.valid?).to be true
    end
  end

  describe 'methods' do
    subject { create :product }

    describe '#is_ordered?' do
      it 'не в заказе' do
        expect(subject.is_ordered?).to be false
      end
    end
  end

  # describe 'Product ecr nomenclature destroy if product item exists and nomenclature empty' do
  #   subject { create :product }
  #
  #   before do
  #     allow(IntegrationModules).to receive(:enable?).with(:ecr).and_return true
  #   end
  #
  #   it do
  #     expect(subject.ecr_nomenclature.quantity).to eq 0
  #
  #     subject.items.create! article: 'Example product item'
  #     expect(subject.reload.ecr_nomenclature.present?).to be false
  #
  #     subject.items.first.destroy!
  #     expect(subject.reload.ecr_nomenclature.present?).to be true
  #   end
  # end
end
