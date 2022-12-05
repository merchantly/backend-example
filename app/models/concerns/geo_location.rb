module GeoLocation
  def geo_location
    return if lng.blank? || lat.blank?

    {
      lng: lng,
      lat: lat
    }
  end

  def google_map_address
    [legal_city, legal_address].select(&:present?).join(', ')
  end
end
