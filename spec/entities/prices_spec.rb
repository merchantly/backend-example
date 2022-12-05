require 'rails_helper'

RSpec.describe Prices, type: :model do
  subject { described_class.new goods: goods }

  let(:goods) { product.goods }

  context 'один товар, без вариантов' do
    let!(:product) { create :product }

    it { expect(subject).not_to have_different_prices }
    it { expect(subject).not_to have_sale }
    it { expect(subject.min_price).to eq product.price }
    it { expect(subject.max_price).to eq product.price }
  end

  context 'товар с вариантами' do
    let!(:product) { create :product }
    let!(:product_item) { create :product_item, product: product }
    let!(:product_item) { create :product_item, product: product }

    it { expect(subject).not_to have_different_prices }
    it { expect(subject).not_to have_sale }
    it { expect(subject.min_price).to eq product.price }
    it { expect(subject.max_price).to eq product.price }
  end

  context 'union' do
    let!(:product) { create :product_union }
    let(:price1) { Money.new 123 }
    let(:price2) { Money.new 123 }
    let!(:part1) { create :product, product_union: product, price: price1 }
    let!(:part2) { create :product, product_union: product, price: price2 }

    it { expect(subject).not_to have_different_prices }
    it { expect(subject).not_to have_sale }
    it { expect(subject.min_price).to eq price1 }
    it { expect(subject.max_price).to eq price2 }
  end
end
