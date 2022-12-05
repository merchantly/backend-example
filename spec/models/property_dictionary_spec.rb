require 'rails_helper'

RSpec.describe PropertyDictionary, type: :model do
  subject { property }

  let(:property) { create :property_dictionary }

  it { expect(subject).to be_persisted }
  it { expect(subject.dictionary.entities).to be_empty }

  describe '#build_attribute_by_string_value' do
    subject { property.build_attribute_by_string_value value }

    let(:value) { 'aaa' }

    it { expect(subject).to be_a AttributeDictionary }
    it { expect(subject.property.dictionary.entities.count).to eq 1 }
    it { expect(subject.property.dictionary.entities.first.name).to eq value }
  end
end
