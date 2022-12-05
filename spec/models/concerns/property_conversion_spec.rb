require 'rails_helper'

RSpec.describe PropertyConversion, type: :model do
  let(:property_dictionary) { create :property_dictionary }

  it 'must not change unless type_changed?' do
    property_dictionary.save!
    expect(property_dictionary.type).to eq 'PropertyDictionary'
  end

  context 'dictionary to string' do
    let(:product) { create :product, :property_dictionary }
    let(:prop) { Property.find(product.data.keys.first) }
    let!(:primitive_value) { prop.entities.first.name }

    before { prop.update_attribute :type, 'PropertyString' }

    it 'must convert entities to primitive values' do
      expect(prop.type).to eq 'PropertyString'
      expect(prop.dictionary_id).to eq nil
      expect(product.reload.data.values.first).to eq primitive_value
    end
  end

  context 'dictionary to integer' do
    let(:product) { create :product, :property_dictionary }
    let(:prop) { Property.find(product.data.keys.first) }
    let!(:primitive_value) { prop.entities.first.name.parse_int.to_s }

    before { prop.update_attribute :type, 'PropertyLong' }

    it 'must convert entities to primitive values' do
      expect(prop.type).to eq 'PropertyLong'
      expect(prop.dictionary_id).to eq nil
      expect(product.reload.data.values.first).to eq primitive_value
    end
  end

  context 'string to dictionary' do
    let(:product) { create :product, :property }
    let(:prop) { Property.find(product.data.keys.first) }
    let!(:primitive_value) { product.data.values.first }
    let(:entity) { DictionaryEntity.find(product.reload.data.values.first) }

    before { prop.update_attribute :type, 'PropertyDictionary' }

    it 'must convert primitive values to entities' do
      expect(prop.type).to eq 'PropertyDictionary'
      expect(prop.dictionary_id).to eq entity.dictionary.id
      expect(entity.name).to eq primitive_value
    end
  end
end
