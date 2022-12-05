class GoogleMapRequestor
  URL = 'https://maps.googleapis.com/maps/api/geocode/json'.freeze

  def self.perform(address)
    response = Faraday.get(URL, address: address, key: Secrets.google_map.api_key)

    result = JSON.parse(response.body).with_indifferent_access

    return [] if result[:status] != 'OK'

    result[:results].map do |location|
      geometry = location[:geometry][:location]

      Location.new address: location[:formatted_address], lng: geometry[:lng], lat: geometry[:lat], query: address
    end
  end

  class Location
    attr_reader :address, :lng, :lat, :query

    def initialize(address:, lng:, lat:, query:)
      @address = address
      @lng = lng
      @lat = lat
      @query = query
    end
  end
end

# {
#     "results" : [
#     {
#     "address_components" : [
#     {
#     "long_name" : "Москва",
#     "short_name" : "Москва",
#     "types" : [ "locality", "political" ]
# },
#     {
#         "long_name" : "Москва",
#         "short_name" : "Москва",
#         "types" : [ "administrative_area_level_2", "political" ]
#     },
#     {
#         "long_name" : "Россия",
#         "short_name" : "RU",
#         "types" : [ "country", "political" ]
#     }
# ],
#     "formatted_address" : "Москва, Россия",
#     "geometry" : {
#     "bounds" : {
#     "northeast" : {
#     "lat" : 56.0214609,
#     "lng" : 37.9678221
# },
#     "southwest" : {
#     "lat" : 55.142591,
#     "lng" : 36.8032249
# }
# },
#     "location" : {
#     "lat" : 55.755826,
#     "lng" : 37.6172999
# },
#     "location_type" : "APPROXIMATE",
#     "viewport" : {
#     "northeast" : {
#     "lat" : 56.0214609,
#     "lng" : 37.9678221
# },
#     "southwest" : {
#     "lat" : 55.142591,
#     "lng" : 36.8032249
# }
# }
# },
#     "place_id" : "ChIJybDUc_xKtUYRTM9XV8zWRD0",
#     "types" : [ "locality", "political" ]
# }
# ],
#     "status" : "OK"
# }
