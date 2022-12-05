require 'rails_helper'

RSpec.describe ProductPrice, type: :model do
  let!(:vendor) { create :vendor }
  let!(:product) { create :product, vendor: vendor }

  context 'не даст создать товар с валютой отличной от вендорской' do
    subject { build :product_price, subject: product, price: Money.new(123, another_currency) }

    let(:another_currency) { Money::Currency.find :usd }

    it { expect(another_currency).not_to eq vendor.default_currency }
    it { expect(subject).not_to be_valid }
    it { expect(subject.save).to eq false }
  end

  context 'удаляем product_price из товара' do
    it do
      allow_any_instance_of(PriceKind).to receive(:reset_min_max_product_prices!)
      product.product_prices.destroy_all

      expect(product.product_prices).to be_empty
    end
  end
end
