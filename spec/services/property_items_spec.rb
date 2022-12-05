require 'rails_helper'

describe PropertyItems, sidekiq: :inline do
  let_it_be(:vendor) { create :vendor }
  subject { described_class.new(vendor: vendor, property: property, filter: filter).available_items }

  let(:filter) { VendorProductsFilter.new vendor: vendor, category_id: category_id }

  describe 'property dictionary' do
    let(:dictionary) { create :dictionary, vendor: vendor }
    let(:property)   { create :property_dictionary, dictionary: dictionary, vendor: vendor }
    let(:entity)     { create :dictionary_entity, dictionary: dictionary, vendor: vendor }

    describe '#available_items' do
      let(:category_id) { nil }
      let(:attribute)         { property.build_attribute_by_value entity.id }
      let(:custom_attributes) { [attribute] }
      let!(:product) { create :product, vendor: vendor, custom_attributes: custom_attributes }
      let(:filter) { VendorProductsFilter.new vendor: vendor, category_id: category_id, dictionary_entity_id: entity.id }

      it do
        expect(subject).to match_array [entity]
      end
    end

    describe '#available_items in category' do
      let!(:category)    { create :category }
      let!(:category_id) { category.id }

      it do
        expect(subject).to match_array []
      end
    end

    describe '#available_items in category' do
      let!(:category)          { create :category, vendor: vendor }
      let!(:category_id)       { category.id }
      let(:attribute)         { property.build_attribute_by_value entity.id }
      let(:custom_attributes) { [attribute] }
      let!(:product) { create :product, vendor: vendor, category: category, custom_attributes: custom_attributes }

      it do
        expect(subject).to match_array [entity]
      end
    end
  end

  describe 'property string' do
    let!(:property) { create :property_string, vendor: vendor }
    let!(:value)    { '123-12' }
    let!(:entity)   { PropertyEntity.new value: value }

    describe '#available_items' do
      let(:category_id) { nil }
      let(:attribute)         { property.build_attribute_by_value value }
      let(:custom_attributes) { [attribute] }
      let!(:product) { create :product, vendor: vendor, custom_attributes: custom_attributes }

      it do
        expect(subject.count).to eq 1
        expect(subject.first).to be_a PropertyEntity
        expect(subject.first.value).to eq value
      end
    end
  end
end
