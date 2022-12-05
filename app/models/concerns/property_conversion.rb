module PropertyConversion
  extend ActiveSupport::Concern

  PRIMITIVE_TYPES = %w[PropertyString PropertyLong].freeze

  included do
    before_update :convert_type
  end

  def values
    @values ||= build_values
  end

  private

  def build_values
    if is_a? PropertyDictionary
      dictionary.present? ? dictionary.entities.alive.ordered : []
    else
      uniq_values.sort
    end
  end

  def convert_type
    return unless will_save_change_to_type?

    if PRIMITIVE_TYPES.include?(type_was) && type == 'PropertyDictionary'
      convert_to_dictionary
    elsif PRIMITIVE_TYPES.include?(type) && type_was == 'PropertyDictionary'
      convert_to_primitive
    end
  end

  def convert_to_dictionary
    dictionary = vendor.dictionaries.create! custom_title: title

    uniq_values.each do |value|
      entity = dictionary.entities.create! custom_title: value.to_s

      set_dictionary_entity_for(vendor.products, entity)
      set_dictionary_entity_for(vendor.product_items, entity)
    end

    update_column :dictionary_id, dictionary.id
  end

  def convert_to_primitive
    dictionary.entities.find_each do |entity|
      set_primitive_value_for(vendor.products, entity)
      set_primitive_value_for(vendor.product_items, entity)
    end

    update_column :dictionary_id, nil
  end

  def uniq_values
    get_values(vendor.products) | get_values(vendor.product_items)
  end

  def get_values(scope)
    goods_with_values(scope).distinct.pluck(Arel.sql("data::hstore -> '#{id}'")).compact
  end

  def set_dictionary_entity_for(goods, entity)
    set_values goods, "#{id}=>\"#{entity.title}\"", "#{id}=>#{entity.id}"
  end

  def set_primitive_value_for(goods, entity)
    entity_name = type == 'PropertyLong' ? entity.title.parse_int : entity.title
    set_values goods, "#{id}=>#{entity.id}", "#{id}=>\"#{entity_name}\""
  end

  def set_values(goods, find_hstore, update_hstore)
    goods = goods.where('data::hstore @> ?', find_hstore)
    goods.update_all ['data = (data || (?)::hstore)', update_hstore]
  end

  def goods_with_values(scope)
    scope.where("data::hstore ? '#{id}'")
  end

  def changed_products_ids
    @changed_products_ids ||= get_changed_ids_for_products | get_changed_ids_for_product_items
  end

  def get_changed_ids_for_products
    goods_with_values(vendor.products.active).pluck(:id)
  end

  def get_changed_ids_for_product_items
    goods_with_values(vendor.product_items).pluck(:product_id)
  end
end
