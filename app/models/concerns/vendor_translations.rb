module VendorTranslations
  extend ActiveSupport::Concern

  included do
    delegate :translate, to: :i18n
  end

  def i18n
    @i18n ||= I18n::Backend::Vendor.new(self)
  end

  def all_translations(locale)
    Rails.cache.fetch [:vendor_translations, id, locale, cache_sweeped_at, translations_updated_at, :v18] do
      VendorTranslationsService.new(self).all_translations[locale]
    end
  end
end
