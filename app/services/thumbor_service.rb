class ThumborService
  include ActionView::Helpers::AssetUrlHelper
  extend ThumborRails::Helpers

  def self.url(image_url: nil, width: nil, height: nil, filters: [])
    if ThumborRails.server_url
      params = { unsafe: true }
      params[:width] = width
      params[:height] = height
      params[:filters] = filters
      thumbor_url image_url, params
    else
      image_url
    end
  end

  def initialize(image)
    @image = image.is_a?(ProductImage) ? image.image : image # может быть nil
  end

  def url(width: nil, height: nil, filters: [])
    image_url = if Rails.env.development?
                  image.url
                else
                  image.present? ? image.url : ImageUploader.new.default_url
                end
    self.class.url image_url: image_url, width: width, height: height, filters: filters
  end

  private

  attr_reader :image
end
