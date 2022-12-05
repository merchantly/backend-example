require 'rails_helper'

describe API::Entity::ProductCustomAttributes do
  include BuildCustomAttributes
  subject { described_class.represent(product).as_json }

  let!(:vendor) { create :vendor }
  let!(:property) { create :property_dictionary, vendor: vendor }
  let(:title) { 'adsadassadasd' }
  let(:entity_id) { ProductBuilder::NEW_ID }
  let!(:custom_attributes) { { property.id => { dictionary_entity_id: entity_id, dictionary_entity_title: title } } }

  let!(:product) do
    p = build :product, vendor: vendor

    p.custom_attributes = build_custom_attributes vendor, custom_attributes
    p
  end

  it do
    ca = subject['customAttributes'].first
    expect(ca['value']).to eq entity_id
    expect(ca['readableValue']).to eq title

    property = subject['properties'].first
    dictionary = property['dictionary']
    entities = dictionary['entities']
    entity = { 'id' => entity_id, 'title' => title }
    expect(entities.first).to be_eql entity
  end
end
