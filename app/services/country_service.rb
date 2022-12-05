class CountryService
  class << self
    def list
      all_codes.map { |code| { code: code, title: translate_by_code(code) } }.sort_by { |item| item[:title] }
    end

    def all_codes
      ISO3166::Country.codes
    end

    def translate_by_code(code)
      country = ISO3166::Country.new(code)

      CountrySelect::FORMATS[:default].call(country)
    end
  end
end
