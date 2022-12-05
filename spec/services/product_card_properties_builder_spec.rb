require 'rails_helper'

describe ProductCardPropertiesBuilder do
  subject { described_class.new(product).properties }

  let(:vendor) { product.vendor }

  describe 'без свойств' do
    context 'Объединенные товар' do
      let(:product) { create :product_union, :products }

      it { expect(product.goods).not_to be_empty }
      it { expect(subject).to be_empty }
    end

    context 'Товар с вариантами' do
      describe 'нет вариантов' do
        let(:product) { create :product, :ordering }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to be_empty }
      end

      describe 'есть варианты' do
        let(:product) { create :product, :ordering, :items }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to be_empty }
      end
    end
  end

  describe 'со свойствами' do
    context 'Объединенные товар' do
      describe 'подтовары без свойств' do
        let(:product) { create :product_union }
        let!(:product1) { create :product, :ordering, product_union: product }
        let!(:product2) { create :product, :ordering, product_union: product }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to be_empty }
      end

      describe 'подтовары с уникальными свойствами' do
        let(:product) { create :product_union }
        let!(:product1) { create :product, :ordering, :property, vendor: vendor, product_union: product }
        let!(:product2) { create :product, :ordering, :property, vendor: vendor, product_union: product }
        let!(:product3) { create :product, :ordering, :property, vendor: vendor, product_union: product }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to have(3).items }
      end

      describe 'подтовары с одинаковым свойством' do
        let(:product) { create :product_union }
        let(:property) { create :property_string, vendor: product.vendor }
        let(:custom_attributes) { [property.build_attribute_by_value('some')] }
        let!(:product1) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes, product_union: product }
        let!(:product2) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes, product_union: product }
        let!(:product3) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes, product_union: product }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to have(0).items }
      end

      describe 'подтовары с одинаковым свойствами, кроме одного' do
        let(:product) { create :product_union }
        let(:property) { create :property_string, vendor: product.vendor }
        let(:custom_attributes) { [property.build_attribute_by_value('some')] }
        let!(:product1) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes, product_union: product }
        let!(:product2) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes, product_union: product }
        let!(:product3) { create :product, :ordering, vendor: vendor, product_union: product }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to have(1).items }
      end

      describe 'подтовары с одним свойством и разными значениями' do
        let(:product) { create :product_union }
        let(:property) { create :property_string, vendor: product.vendor }
        let(:custom_attributes1) { [property.build_attribute_by_value('some1')] }
        let(:custom_attributes2) { [property.build_attribute_by_value('some2')] }
        let(:custom_attributes3) { [property.build_attribute_by_value('some3')] }
        let!(:product1) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes1, product_union: product }

        context 'еще два продаваемых товара' do
          let!(:product2) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes2, product_union: product }
          let!(:product3) { create :product, :ordering, vendor: vendor, custom_attributes: custom_attributes3, product_union: product }

          it { expect(product.goods).not_to be_empty }
          it { expect(subject).to have(1).items }
        end

        context 'один продаваемый, остальные нет' do
          let!(:product2) { create :product, vendor: vendor, custom_attributes: custom_attributes2, product_union: product }
          let!(:product3) { create :product, vendor: vendor, custom_attributes: custom_attributes3, product_union: product }

          it { expect(product.goods).not_to be_empty }
          it { expect(subject).to have(1).items }
        end
      end
    end

    context 'Товар с вариантами' do
      describe 'нет вариантов' do
        let(:product) { create :product, :ordering, :property }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to be_empty }
      end

      describe 'есть вариант с одним свойством' do
        let(:product) { create :product, :ordering, :property }
        let!(:product_item) { create :product_item, :ordering, :property, product: product }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to be_empty }
      end

      describe 'есть варианты с разными свойствами' do
        let(:product) { create :product, :ordering, :property }
        let!(:product_item1) { create :product_item, :ordering, :property, product: product }
        let!(:product_item2) { create :product_item, :ordering, :property, product: product }

        it { expect(product.goods).not_to be_empty }
        it { expect(subject).to have(2).items }
      end
    end
  end
end
