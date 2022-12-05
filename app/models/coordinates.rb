class Coordinates
  attr_accessor :latitude, :longitude

  # new "(56,46)"
  # or
  # new 56, 46
  def initialize(lng = nil, lat = nil)
    @latitude = lng
    @longitude = lat
  end

  def blank?
    latitude.nil? && longitude.nil?
  end

  def present?
    present?
  end

  def to_s
    "(#{latitude}, #{longitude})"
  end

  def to_a
    [latitude, longitude]
  end
end
