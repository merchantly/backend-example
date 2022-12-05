require 'rails_helper'

describe Export::YandexMarket::Yml do
  subject { described_class.new(vendor) }

  let(:vendor) { create :vendor, :with_ordering_products }

  let!(:product_union) { create :product_union, vendor: vendor }

  before do
    product_union.products << product1
    product_union.products << product2
  end

  context 'разные цены у вариантов товаров' do
    let(:product1) { create :product, :ordering, price: Money.new(100), vendor: vendor }
    let(:product2) { create :product, :ordering, price: Money.new(200), vendor: vendor }

    it do
      xml = subject.generate
      expect(xml.doc.xpath('//shop//offer').count).to eq(4)
      expect(xml).to be_a Nokogiri::XML::Builder
    end
  end

  context 'одинаковые цены у вариантов товаров' do
    let(:product1) { create :product, :ordering, price: Money.new(200), vendor: vendor }
    let(:product2) { create :product, :ordering, price: Money.new(200), vendor: vendor }

    it do
      expect { subject.generate }.not_to raise_error
    end
  end
end
