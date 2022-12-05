module CachedDescriptionHstore
  extend ActiveSupport::Concern

  included do
    before_validation :cache_description
  end

  private

  def cache_description
    self.cached_description_translations = if custom_description_translations.is_a?(Hash) && custom_description_translations.values.any?(&:present?)
      custom_description_translations
                                           else
                                             { HstoreTranslate.default_locale => stock_description }
                                           end
  end
end
