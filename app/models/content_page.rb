class ContentPage < ApplicationRecord
  include Archivable
  include Sortable
  include Authority::Abilities
  include Droppable
  include CurrentVendor
  include Slugable
  include SeoFields
  include RoutesConcern

  belongs_to :vendor
  has_many :images, class_name: '::ContentPageImage'
  has_many :menu_items, dependent: :destroy

  scope :for_auto_menu, -> { alive }
  scope :by_title, ->(title) { where "? = ANY(avals(#{arel_table.name}.title_translations))", title }

  # validates :title, :content, presence: true
  validates :title, presence: true
  translates :title, :content

  # для meta
  def description
    content
  end

  def mandatory_image
    image || ContentPageImage.new(content_page: self).image
  end

  def image
    return if images.blank?

    images.first.image
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_title?
  end

  def to_s
    title
  end

  def default_path(params = {})
    vendor_page_path to_param, params
  end
end
