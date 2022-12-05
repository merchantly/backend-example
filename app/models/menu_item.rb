class MenuItem < ApplicationRecord
  include Sortable
  include Authority::Abilities
  include Archivable

  PLACES = [
    PLACE_TOP = 'top'.freeze,
    PLACE_BOTTOM_LEFT = 'bottom_left'.freeze,
    PLACE_BOTTOM_RIGHT = 'bottom_right'.freeze
  ].freeze

  belongs_to :vendor, touch: :menu_updated_at

  belongs_to :dictionary
  belongs_to :dictionary_entity
  belongs_to :category
  belongs_to :lookbook
  belongs_to :content_page

  scope :includeses, -> { includes :dictionary, :dictionary_entity, :lookbook, content_page: [:slug], category: %i[slug vendor] }

  scope :by_place, ->(place) { where place: place }

  ranks :position, with_same: %i[place vendor_id], class_name: 'MenuItem', scope: :alive

  validates :place, inclusion: PLACES

  translates :custom_title

  before_save do
    raise 'Cant be MenuItem' if instance_of?(MenuItem)
  end

  def self.valid_place?(place)
    PLACES.include? place
  end

  def self.humanized_name
    I18n.t name, scope: 'operator.headings.menu_items'
  end

  def humanized_type_name
    self.class.humanized_name
  end

  def place_name
    I18n.t place, scope: 'operator.headings.menu_items'
  end

  def target_blank?
    false
  end

  def to_s
    title
  end

  def link_target
    target_blank? ? '_blank' : ''
  end

  def url
    raise 'not implemented'
  end

  def title
    custom_title.presence || entity_title
  end

  def children
    []
  end

  def products_count
    nil
  end

  def entity
    nil
  end

  def entity_title
    raise 'not implemented'
  end
end

class MenuItem
  AVAILABLE = [MenuItemCategory, MenuItemLink, MenuItemPage, MenuItemDictionary, MenuItemDictionaryEntity, MenuItemBlog, MenuItemLookbook].freeze
end
