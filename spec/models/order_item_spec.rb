require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  subject do
    described_class.create! good: cart_item.good,
                            total_sale_amount: Money.zero,
                            order: order,
                            price: cart_item.price.exchange_to(order.currency),
                            count: cart_item.count,
                            title: cart_item.title,
                            weight: cart_item.weight,
                            weight_of_price: cart_item.weight_of_price,
                            selling_by_weight: cart_item.selling_by_weight?
  end

  let(:price)      { Money.new 123, :rub }
  let(:order)      { create :order }

  context 'by the piece' do
    let(:product)    { create :product, price: price }
    let(:cart_item)  { create :cart_item, good: product, product_price: product.default_product_price }

    it do
      expect(subject.price).to eq price
    end

    it do
      expect(subject.title).to eq product.title
    end

    it do
      expect(subject).to be_valid
    end

    it do
      expect(subject).to be_valid
    end
  end

  describe 'bulk' do
    let(:product)    { create :product, price: price, selling_by_weight: true }

    let(:cart_item)  { create :cart_item, good: product, weight: 2.0, product_price: product.default_product_price }

    context 'valid' do
      it do
        expect(subject).to be_valid
      end

      it do
        expect(subject.total_price).to eq price * 2
      end
    end

    context 'invalid' do
      it do
        subject.weight = 0
        expect(subject).not_to be_valid
      end
    end
  end
end
