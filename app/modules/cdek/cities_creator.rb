class Cdek::CitiesCreator
  FOLDER_PATH = Rails.root.join('tmp/CDEK_city')
  CDEK_CITIES_PATH = Rails.root.join('config/cdek_cities.json')

  def self.perform
    # Download and unpack archive from https://cdek.ru/storage/source/document/1/CDEK_city.zip to tmp folder

    files = Dir["#{FOLDER_PATH}/*.xls"]

    cities = []

    files.each do |file|
      sheet = Roo::Excel.new(file).sheet(0)

      sheet.each(id: 'ID', name: 'CityName', post_codes: 'PostCodeList', country: 'CountryName', obl_name: 'OblName') do |hash|
        cities << { id: hash[:id].to_i, name: hash[:name], post_codes: hash[:post_codes].presence, country: hash[:country], obl_name: hash[:obl_name] }
      end
    end

    File.write(CDEK_CITIES_PATH, cities.to_json)
  end
end
