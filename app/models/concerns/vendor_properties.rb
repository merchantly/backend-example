module VendorProperties
  extend ActiveSupport::Concern
  included do
    has_many :properties, dependent: :destroy
    # Ключевое свойство варианта (цвет, размер или другое)
    belongs_to :key_item_property, class_name: 'Property'

    accepts_nested_attributes_for :properties
  end

  def safe_key_item_property
    key_item_property || properties.used_in_items.ordered_for_item.first
  end

  def property_by_title(title)
    with_lock do
      properties.by_title(title).first || properties.create!(title: title, type: 'PropertyString')
    end
  end
end
