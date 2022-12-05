require 'rails_helper'

RSpec.describe PriceKind, type: :model do
  let!(:vendor) { create :vendor }
  let!(:price_kind) { create :price_kind, title: 'test', vendor: vendor }

  it do
    expect(price_kind).to be_persisted
  end

  context do
    let!(:product) { create :product, vendor: vendor }
    let!(:product_price) { product.product_prices.create! price_kind: price_kind }

    it do
      expect(price_kind.reset_min_max_product_prices!).to be_truthy
    end
  end
end
