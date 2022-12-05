module CachedTitleHstore
  extend ActiveSupport::Concern

  included do
    before_validation :cache_title
    scope :ordered,          -> { order Arel.sql("#{arel_table.name}.cached_title_translations::hstore -> '#{HstoreTranslate.locale}'") }
    scope :ordered_by_title, -> { order Arel.sql("#{arel_table.name}.cached_title_translations::hstore -> '#{HstoreTranslate.locale}'") }
    scope :by_title,         ->(title) { where "? = ANY(avals(#{arel_table.name}.cached_title_translations))", title }
    scope :by_titles,        ->(titles) { where "string_to_array(?, ',') && avals(#{arel_table.name}.cached_title_translations)", titles.join(',') }

    scope :by_name,          ->(title) { by_title title }

    scope :by_ilike_title,   ->(title) { where("EXISTS (SELECT FROM unnest(avals(#{arel_table.name}.cached_title_translations)) el WHERE el ILIKE ?)", "#{title}%") }
  end

  def cached_title_with_translations
    cached_title_translations.values.join(', ')
  end

  private

  def cache_title
    self.cached_title_translations = if custom_title_translations.is_a?(Hash) && custom_title_translations.values.any?(&:present?)
      custom_title_translations
                                     else
                                       { HstoreTranslate.default_locale => stock_title }
                                     end
  end
end
