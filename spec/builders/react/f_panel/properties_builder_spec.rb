require 'rails_helper'

RSpec.describe React::FPanel::PropertiesBuilder, type: :model do
  let!(:vendor)   { create :vendor, :product_with_property }
  let!(:category) { create :category, vendor: vendor }
  let!(:property) { create :property_string, vendor: vendor }

  context 'с категорией' do
    subject do
      described_class.new(vendor: vendor, category_id: category.id).build
    end

    let!(:custom_attributes) { [property.build_attribute_by_value('test')] }
    let!(:product) { create :product, categories: [category], vendor: vendor, custom_attributes: custom_attributes }

    it 'должен вернуть cвойства, используемых в продуктах' do
      expect(subject).to match_array [property]
    end
  end

  context 'без категории' do
    subject do
      described_class.new(vendor: vendor).build
    end

    it 'контролька' do
      expect(vendor.properties).to have(2).items
    end

    it do
      expect(subject).to match_array vendor.properties
    end
  end
end
