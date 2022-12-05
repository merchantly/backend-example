class Cdek::Cities
  CITIES_PATH = Rails.root.join('config/cdek_cities.json')

  class << self
    def find_by_name(name)
      search_name = name.strip.upcase

      all.select do |city|
        city_name = city[:name].to_s.upcase

        (city_name == search_name) || (city_name.split(',').first == search_name) || (city_name.split.first == search_name)
      end
    end

    def all
      @all ||= import
    end

    def import
      return [] unless File.exist?(CITIES_PATH)

      import!
    end

    def import!
      @all = JSON.parse(File.read(CITIES_PATH)).map(&:symbolize_keys)
    end
  end
end
