require 'rails_helper'

describe CartItemDecorator do
  subject { described_class.decorate cart_item }

  let(:cart_item) { create :cart_item, good: good, product_price: good.default_product_price }

  context 'товар' do
    describe 'без кастомных аттрибутов не имеет details' do
      let(:good) { create :product }

      it { expect(subject.details).to be_blank }
    end

    describe 'с кастомными аттрибутами они и показываются' do
      let!(:attribute) { build :attribute_string }
      let(:good) { create :product, custom_attributes: [attribute] }

      # <div class=\"b-cart__item__option\">Атрибут 1: dictionary_entity1</div>
      it { expect(subject.details).to include attribute.title }
    end
  end

  context 'модификация' do
    describe 'без кастомных аттрибутов это название модификации' do
      let(:good) { create :product_item }

      it { expect(good.title).not_to eq good.product.title }
      it { expect(subject.details).to eq good.title }
    end

    describe 'с кастомными аттрибутами они и показываются' do
      let!(:attribute) { build :attribute_string }
      let(:good) { create :product_item, custom_attributes: [attribute] }

      # <div class=\"b-cart__item__option\">Атрибут 1: dictionary_entity1</div>
      it { expect(subject.details).to include attribute.title }
    end
  end

  # Убедиться что отдается правильный details для таких видов товаров:
  # 1. ProductItem default
  # 2. ProductItem not default
  # 3. Product with custom_atributes
  # 4. Product without custom-attributes
  # ZZ
end
