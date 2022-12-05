require 'rails_helper'

describe TaxCalculator do
  describe do
    let(:price) { Money.new 12_100, 'RUB' }
    let(:vendor) { create :vendor, tax_type: 'tax_ru_4' }
    let(:tax_price) { Money.new 2178, 'RUB' }

    it do
      expect(described_class.new(price: price, vendor: vendor).perform).to eq tax_price
    end
  end
end
