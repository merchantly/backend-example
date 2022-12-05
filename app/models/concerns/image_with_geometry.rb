module ImageWithGeometry
  extend ActiveSupport::Concern

  included do
    before_save :setup_geometry
  end

  def geometry
    Geometry.new(width: width, height: height).freeze
  end

  def update_geometry!
    setup_geometry
    update_columns width: width, height: height
  end

  private

  def setup_geometry
    self.width, self.height = image.geometry
  end
end
