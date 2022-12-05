require 'rails_helper'

RSpec.describe StockedItem, type: :model do
  let(:vendor) { create :vendor, :moysklad }
  let(:quantity) { nil }
  let(:product) { create :product, vendor: vendor, quantity: quantity }

  describe '#quantity_infinity?' do
    it { expect(product).to be_quantity_infinity }
  end

  describe '#orderable_quantity' do
    let(:q) { 2 }

    context 'если максимальное количество товаров не ограничено, то всегда возвращает true' do
      it { expect(product.max_orderable_quantity).to eq vendor.max_orderable_quantity }
      it { expect(product).to be_orderable_quantity(q) }
    end

    context do
      let(:quantity) { 12 }

      it { expect(product.max_orderable_quantity).to eq quantity }
      it { expect(product).to be_orderable_quantity(q) }

      context 'больше существующего уже не заказать' do
        it { expect(product).not_to be_orderable_quantity(quantity + 1) }
      end
    end
  end

  describe '#update_quantity!' do
    subject { product }

    let(:quantity) { 1 }

    it 'контролька' do
      expect(subject.quantity).to eq quantity
    end

    it do
      subject.update_quantity!(-1)
      expect(subject.reload.quantity).to eq 0
    end
  end
end
