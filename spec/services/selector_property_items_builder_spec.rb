require 'rails_helper'

describe SelectorPropertyItemsBuilder do
  let!(:vendor) { create :vendor }
  let!(:property_one) { create :property_string, vendor: vendor }
  let!(:property_two) { create :property_string, vendor: vendor }

  let!(:product_union) { create :product_union, vendor: vendor }
  let!(:product_one) { create :product, vendor: vendor, product_union: product_union, custom_attributes: [property_one.build_attribute_by_value('value_one'), property_two.build_attribute_by_value('value_one')] }
  let!(:product_two) { create :product, vendor: vendor, product_union: product_union, custom_attributes: [property_one.build_attribute_by_value('value_one'), property_two.build_attribute_by_value('value_two')] }
  let!(:product_three) { create :product, vendor: vendor, product_union: product_union, custom_attributes: [property_one.build_attribute_by_value('value_two'), property_two.build_attribute_by_value('value_one')] }
  let!(:product_four) { create :product, vendor: vendor, product_union: product_union, custom_attributes: [property_one.build_attribute_by_value('value_two'), property_two.build_attribute_by_value('value_two')] }

  it do
    expect(described_class.new(property_one, product_union).items.count).to eq(2)
    expect(described_class.new(property_two, product_union).items.count).to eq(2)
  end
end
