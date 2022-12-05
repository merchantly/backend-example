module I18n
  module Backend
    class Vendor < Simple
      def initialize(vendor)
        @vendor = vendor
      end

      def load_translations
        I18n.available_locales.each do |locale|
          default = I18n.backend.translate locale, :vendor
          data = vendor.all_translations(locale) || {}
          store_translations locale, default.deep_merge(data)
        end
      end

      private

      attr_reader :vendor
    end
  end
end
