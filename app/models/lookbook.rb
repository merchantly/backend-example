class Lookbook < ApplicationRecord
  include Authority::Abilities
  include Archivable
  include Activable
  include Sortable
  include CurrentVendor
  include Slugable
  include SeoFields
  include RoutesConcern

  belongs_to :vendor
  has_many :images, class_name: '::LookbookImage'
  has_many :menu_items, dependent: :destroy

  validates :title, presence: true

  # для meta
  def description; end

  def mandatory_image
    image || LookbookImage.new(lookbook: self).image
  end

  def to_s
    title
  end

  def default_path(params = {})
    vendor_lookbook_path to_param, params
  end

  protected

  def image
    return if images.blank?

    images.first.image
  end
end
