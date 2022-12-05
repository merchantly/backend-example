require 'rails_helper'

describe ProductPriceFinder do
  subject { described_class.new(client_category: client_category, good: product).perform }

  let!(:vendor) { create :vendor }
  let!(:product) { create :product, vendor: vendor, price: Money.new(20, :rub), sale_price: Money.new(18, :rub) }

  # Виды цен
  let!(:default_price_kind) { vendor.default_price_kind }
  let!(:sale_price_kind) { vendor.sale_price_kind }
  let!(:price_kind_1) { create :price_kind, title: 'Оптовые', vendor: vendor }
  let!(:price_kind_2) { create :price_kind, title: 'Другое', vendor: vendor }

  # Цены продукта
  let!(:default_price) { product.default_product_price }
  let!(:sale_price) { product.sale_product_price }
  let!(:product_price_1) { create :product_price, subject: product, price_kind: price_kind_1, price:  Money.new(14, :rub) }
  let!(:product_price_2) { create :product_price, subject: product, price_kind: price_kind_2, price:  Money.new(17, :rub) }

  # Категории пользователей
  let!(:anonymous_category) { vendor.anonymous_client_category }
  let!(:registered_category) { vendor.default_client_category }
  let!(:client_category_1) { create :client_category, title: 'Оптовики', vendor: vendor, all_prices_available: false }

  describe 'Оптовики - Доступна только конкретная цена для конкретной категории' do
    let(:client_category) { client_category_1 }

    let!(:client_category_price_kind) { create :client_category_price_kind, price_kind: price_kind_1, client_category: client_category, available: true }

    it do
      expect(subject).to eq product_price_1
    end
  end

  describe 'Зарегистрированному пользовтелю самая дешевая цена,кроме оптовики' do
    let(:client_category) { registered_category }

    let!(:client_category_price_kind_1) { create :client_category_price_kind, price_kind: default_price_kind, client_category: client_category, available: true }
    let!(:client_category_price_kind_2) { create :client_category_price_kind, price_kind: sale_price_kind, client_category: client_category, available: true }
    let!(:client_category_price_kind_3) { create :client_category_price_kind, price_kind: price_kind_2, client_category: client_category, available: true }

    before do
      client_category.update! all_prices_available: false
    end

    it do
      expect(subject).to eq product_price_2
    end
  end
end
