class AssetImage < ApplicationRecord
  include Authority::Abilities
  include ImageWithGeometry

  belongs_to :vendor
  mount_uploader :image, AssetImageUploader

  validates :image, presence: true

  delegate :adjusted_url, to: :image
end
