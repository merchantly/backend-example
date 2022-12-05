module ValidateImageGeometry
  IMAGE_WIDTH = 940
  extend ActiveSupport::Concern

  included do
    validate :image_width
  end

  private

  def image_width
    unless width == IMAGE_WIDTH
      errors.add :image, I18n.t('errors.image.width_not_fits', width: IMAGE_WIDTH)
    end
  end
end
