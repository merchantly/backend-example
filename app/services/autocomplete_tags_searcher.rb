class AutocompleteTagsSearcher
  LIMIT = 20

  def initialize(current_vendor:, locale:, query:)
    @current_vendor = current_vendor
    @query = query
    @locale = locale || current_vendor.default_locale
  end

  def perform
    items
  end

  private

  def items
    scope.page(1).per(LIMIT)
  end

  def scope
    current_vendor.tags.where('tags.title_translations->:locale ilike :query', locale: locale, query: "%#{query}%")
  end

  attr_reader :current_vendor, :locale, :query
end
