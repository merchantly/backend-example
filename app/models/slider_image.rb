class SliderImage < ApplicationRecord
  include Sortable
  include Authority::Abilities
  include Archivable
  include ImageWithGeometry
  include LinkTarget

  belongs_to :vendor, touch: :slider_images_updated_at

  mount_uploader :image, ImageUploader

  validates :image,
            on: :create, # Проверяем только при создании. Иначе на arhive! может ругаться на размер и не удалять, при этом падать с 422
            presence: true,
            file_size: {
              less_than: ImageUploader::IMAGE_SIZE_RANGE.max
            }

  delegate :adjusted_url, to: :image
end
