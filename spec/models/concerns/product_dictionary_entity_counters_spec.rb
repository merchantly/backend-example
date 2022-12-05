require 'rails_helper'

RSpec.describe ProductDictionaryEntityCounters, type: :model, sidekiq: :inline do
  let!(:vendor)            { create :vendor }
  let!(:property)          { create :property_dictionary, vendor: vendor }
  let!(:dictionary)        { property.dictionary }
  let!(:dictionary_entity) { create :dictionary_entity, vendor: vendor, dictionary: dictionary }
  let!(:attribute)         { property.build_attribute_by_value dictionary_entity.id }
  let!(:custom_attributes) { [attribute] }

  it 'изначально счетчик чист' do
    # products_count_sql = products.common.select('COUNT(*)').to_sql
    # active_products_count_sql = products.active.common.select('COUNT(*)').to_sql
    # published_products_count_sql = products.common.published.select('COUNT(*)').to_sql
    # archived_products_count_sql = products.common.archive.select('COUNT(*)').to_sql
    expect(dictionary_entity.products_count).to eq 0
    expect(dictionary_entity.active_products_count).to eq 0
  end

  context 'атрибуты товара' do
    let!(:product) { create :product, vendor: vendor, custom_attributes: custom_attributes }

    it do
      expect(product.dictionary_entity_ids).to eq [dictionary_entity.id]
      expect(dictionary_entity.reload.products_count).to eq 1
      expect(dictionary_entity.reload.active_products_count).to eq 1

      product.destroy!

      expect(dictionary_entity.reload.products_count).to eq 0
      expect(dictionary_entity.reload.active_products_count).to eq 0
    end
  end

  context 'атрибуты items-ов' do
    let!(:product)      { create :product, vendor: vendor, custom_attributes: [] }
    let!(:product_item) { create :product_item, :ordering, product: product, vendor: vendor, custom_attributes: custom_attributes }

    it do
      expect(product.dictionary_entity_ids).to eq [dictionary_entity.id]
    end
  end

  context 'атрибуты good-ов' do
    let!(:product)           { create :product, vendor: vendor, custom_attributes: custom_attributes }
    let!(:product_union)     { create :product_union, products: [product] }

    it do
      expect(product_union.dictionary_entity_ids).to eq [dictionary_entity.id]
    end
  end
end
