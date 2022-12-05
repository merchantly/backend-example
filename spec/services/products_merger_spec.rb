require 'rails_helper'

describe ProductsMerger do
  let!(:vendor) { create :vendor, :with_products }
  let!(:products) { vendor.products }

  let(:merger) { described_class.new vendor }

  describe '#merge!' do
    subject { merger.merge! products }

    it { expect(subject).to be_a ProductUnion }
    it { expect(subject.products).to have(3).items }
    it { expect(products).not_to include(subject) }

    specify do
      subject
      expect(products.first).to be_is_part_of_union
    end

    context 'замержили свои части, ничего не изменилось' do
      subject { merger.merge! products }

      let!(:union) { create :product_union, :products, vendor: vendor }
      let!(:products) { union.products }

      it { expect(products).to have(3).items }
      it { expect(subject).to eq union }
      it { expect(subject.products.map(&:id).sort).to eq products.map(&:id).sort }
    end

    context 'замержили одну чужую часть, она включилась в объединение в котором больше товаров' do
      let!(:union)    { create :product_union, :products, vendor: vendor }
      let!(:product)  { create :product, vendor: vendor }
      let!(:products) { vendor.products.where(id: union.products.map(&:id) + [product.id]) }

      it { expect(subject).to eq union }
      it { expect(subject.products.to_a).to have(4).items }
      it { expect(subject.products).to include(product) }
    end

    context 'одно объединение и один товар' do
      let!(:union)   { create :product_union, :products, vendor: vendor }
      let!(:product) { create :product, vendor: vendor }
      let!(:products) { Product.where id: [union.id, product.id] }

      it { expect(subject).to eq union }
      it { expect(subject.products).to include(product) }
    end

    context 'один продукт с вариантами' do
      let!(:first_product) { create :product, vendor: vendor }
      let!(:second_product) { create :product, :items, vendor: vendor }
      let!(:products) { Product.where id: [first_product.id, second_product.id] }

      it { expect { subject }.not_to raise_error described_class::ProductsWithOptionsError }
    end

    context 'два продукта с вариантами' do
      let!(:first_product) { create :product, :items, vendor: vendor }
      let!(:second_product) { create :product, :items, vendor: vendor }
      let!(:products) { Product.where id: [first_product.id, second_product.id] }

      it { expect { subject }.to raise_error described_class::ProductsWithOptionsError }
    end

    context 'много объединений' do
      let!(:union)   { create :product_union, :products, vendor: vendor }
      let!(:union2)  { create :product_union, :products, vendor: vendor }
      let!(:products) { Product.where id: [union.id, union2.id] }

      it { expect { subject }.to raise_error described_class::ManyUnionsError }
    end
  end
end
