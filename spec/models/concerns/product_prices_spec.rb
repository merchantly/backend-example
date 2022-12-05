require 'rails_helper'

RSpec.describe ProductPrices, type: :model do
  let(:product) { create :product, price: price }

  context 'По-умолчанию у товара может не быть цены' do
    let(:price) { nil }

    it { expect(product.price).to be_nil }
  end

  context 'Устанавливаем цену при создании товара' do
    let(:price) { Money.new 123 }
    let(:new_price) { Money.new 456 }

    it { expect(product.price).to eq price }

    it do
      product.price = new_price
      expect(product).to be_changed
      expect(product).to be_price_changed
      expect(product.price).to eq new_price
    end

    context 'цену можно изменить через update' do
      before do
        product.update price: new_price
      end

      it { expect(product.price).to eq new_price }
      it { expect(product.reload.price).to eq new_price }
    end
  end

  context 'товар не сохраненный' do
    let(:price) { Money.new 123 }
    let(:new_price) { Money.new 456 }
    let(:product) { build :product, price: price }

    it { expect(product.price).to eq price }

    it do
      product.price = new_price
      expect(product).to be_changed
      expect(product).to be_price_changed
      expect(product.price).to eq new_price
    end
  end
end
