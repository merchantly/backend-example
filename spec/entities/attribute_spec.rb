require 'rails_helper'

RSpec.describe Attribute, type: :model do
  let!(:vendor)   { create :vendor }
  let!(:property) { create :property_string, vendor: vendor }
  let(:value) { 'some' }

  describe 'Разные аттрибуты одного свойства с одним значением считаются идентичными' do
    let(:attr1) { property.build_attribute_by_value value }
    let(:attr2) { property.build_attribute_by_value value }

    it { expect(attr1).to be_a AttributeString }
    it { expect(attr2).to be_a AttributeString }

    it { expect(attr1).to eq attr2 }
    it { expect(attr1 == attr2).to be_truthy }
    it { expect(attr1).not_to eql attr2 }
  end

  context 'factory AttributeString' do
    subject { build :attribute_string }

    it { expect(subject).to be_present }
  end

  context 'factory AttributeDictionary' do
    subject { build :attribute_dictionary }

    it { expect(subject).to be_present }
  end

  describe 'Атрибут с новым свойством' do
    subject { new_property.build_attribute value: 'value' }

    let(:new_property) { PropertyString.new vendor: vendor, title: 'title', id: ProductBuilder::NEW_ID }

    it do
      subject.save
      expect(subject.property).to be_persisted
      expect(subject.property.id < ProductBuilder::NEW_ID).to be_truthy
    end
  end
end
