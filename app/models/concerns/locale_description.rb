# for pg_search_scope
module LocaleDescription
  extend ActiveSupport::Concern

  included do
    before_validation :set_locale_descriptions, if: :will_save_change_to_cached_description_translations?
  end

  private

  def set_locale_descriptions
    I18n.available_locales.each do |locale|
      send("locale_description_#{locale}=", cached_description_translations[locale.to_s])
    end
  end
end
