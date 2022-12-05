class ContentPageImage < ApplicationRecord
  include Authority::Abilities
  include RankedModel
  include ImageWithGeometry

  belongs_to :content_page
  belongs_to :vendor
  mount_uploader :image, ImageUploader

  ranks :position, with_same: %i[content_page_id vendor_id]
  scope :alive, -> { all }
  scope :ordered, -> { rank :position }

  before_validation do
    self.vendor_id ||= content_page.try(:vendor_id)
  end

  validates :image, presence: true

  delegate :adjusted_url, to: :image

  # Для совместимости с cell slider1:w
  #
  def link_url; end

  def link_target
    '_blank'
  end
end
