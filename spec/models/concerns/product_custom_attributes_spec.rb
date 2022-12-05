require 'rails_helper'

RSpec.describe ProductCustomAttributes, type: :model do
  let!(:vendor) { create :vendor }

  context 'product with items' do
    let!(:product_property)          { create :property_dictionary, vendor: vendor }
    let!(:product_dictionary)        { product_property.dictionary }
    let!(:product_dictionary_entity) { create :dictionary_entity, vendor: vendor, dictionary: product_dictionary }
    let!(:product_attribute)         { product_property.build_attribute_by_value product_dictionary_entity.id }
    let!(:product_custom_attributes) { [product_attribute] }

    let!(:shared_property)          { create :property_dictionary, vendor: vendor }
    let!(:shared_dictionary)        { shared_property.dictionary }
    let!(:shared_item_dictionary_entity) { create :dictionary_entity, vendor: vendor, dictionary: shared_dictionary }
    let!(:shared_item_attribute)         { shared_property.build_attribute_by_value shared_item_dictionary_entity.id }
    let!(:shared_item_custom_attributes) { [shared_item_attribute] }

    let!(:item_property1)          { create :property_dictionary, vendor: vendor }
    let!(:item_dictionary1)        { item_property1.dictionary }
    let!(:item_dictionary_entity1) { create :dictionary_entity, vendor: vendor, dictionary: item_dictionary1 }
    let!(:item_attribute1)         { item_property1.build_attribute_by_value item_dictionary_entity1.id }
    let!(:item_custom_attributes1) { [shared_item_attribute, item_attribute1] }

    let!(:item_property2)          { create :property_dictionary, vendor: vendor }
    let!(:item_dictionary2)        { item_property2.dictionary }
    let!(:item_dictionary_entity2) { create :dictionary_entity, vendor: vendor, dictionary: item_dictionary2 }
    let!(:item_attribute2)         { item_property2.build_attribute_by_value item_dictionary_entity2.id }
    let!(:item_custom_attributes2) { [shared_item_attribute, item_attribute2] }

    let!(:product) { create :product, vendor: vendor, custom_attributes: product_custom_attributes }
    let!(:product_item1) do
      create :product_item, :ordering, product: product, vendor: vendor, custom_attributes: item_custom_attributes1
    end
    let!(:product_item2) do
      create :product_item, :ordering, product: product, vendor: vendor, custom_attributes: item_custom_attributes2
    end

    it 'контрольная проверка' do
      expect(product.custom_attributes).to have(1).items
      expect(product.custom_attributes).to eq product_custom_attributes
    end

    it '#shared_custom_attributes' do
      expect(product.shared_custom_attributes).to have(2).item
      expect(product.shared_custom_attributes).to eq product_custom_attributes + shared_item_custom_attributes
    end

    it '#all_custom_attributes' do
      expect(product.all_custom_attributes).to have(4).item
    end
  end

  context 'product union' do
    subject { create :product_union }

    let!(:shared_property) { create :property_string, vendor: vendor }
    let!(:property1) { create :property_string, vendor: vendor }
    let!(:property2) { create :property_string, vendor: vendor }

    let!(:shared_value) { 'value' }

    let!(:attributes1) { [shared_property.build_attribute_by_value(shared_value), property1.build_attribute_by_value('456')] }
    let!(:attributes2) { [shared_property.build_attribute_by_value(shared_value), property2.build_attribute_by_value('123')] }

    let!(:product1)     { create :product, :ordering, vendor: vendor, custom_attributes: attributes1 }
    let!(:product2)     { create :product, :ordering, vendor: vendor, custom_attributes: attributes2 }

    before do
      subject.products << product1
      subject.products << product2
    end

    it 'контролька' do
      expect(product1.is_ordering).to be true
      expect(product2.is_ordering).to be true
    end

    it { expect(subject.goods).to have(2).items }

    describe '#shared_custom_attributes' do
      it { expect(subject.shared_custom_attributes).to have(1).item }
    end

    describe '#custom_attributes' do
      it { expect(subject.custom_attributes).to have(3).item }
    end
  end
end
