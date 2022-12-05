class VendorTranslationsService
  def initialize(vendor)
    @vendor = vendor
  end

  # TODO Выдавать только переводы указанные в
  # ./config/settings/front_translations.yml
  def all_translations
    I18n.available_locales.index_with do |locale|
      I18n.backend
                      .translate(locale, :vendor)
                      .deep_merge(custom_translations(locale))
    end
  end

  private

  FLATTEN_SEPARATOR = I18n::Backend::ActiveRecord::FLATTEN_SEPARATOR

  attr_reader :vendor

  def custom_translations(locale)
    hash = {}
    Translation.by_vendor(vendor).locale(locale).find_each do |t|
      keys = t.key.split FLATTEN_SEPARATOR
      hash_translation_value hash, keys, t.value
    end

    hash
  end

  def hash_translation_value(hash, keys, value)
    first = keys.shift.to_sym
    if keys.any?
      hash[first] ||= {}
      hash_translation_value hash[first], keys, value
    else
      hash[first] = value
    end
  end
end
