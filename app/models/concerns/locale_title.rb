# for pg_search_scope
module LocaleTitle
  extend ActiveSupport::Concern

  included do
    before_validation :set_locale_titles, if: :will_save_change_to_cached_title_translations?
  end

  private

  def set_locale_titles
    I18n.available_locales.each do |locale|
      send("locale_title_#{locale}=", cached_title_translations[locale.to_s])
    end
  end
end
