class AutocompleteProductsSearcher
  LIMIT = 50

  def initialize(current_vendor:, locale:, query:)
    @current_vendor = current_vendor
    @query = query
    @locale = locale
  end

  def perform
    AutocompleteProductsResult.new items: items
  end

  private

  def items
    scope.page(1).per(LIMIT)
  end

  def scope
    current_vendor.products.alive.where('(products.cached_title_translations->:locale ilike :query) or (products.article ilike :query)', locale: locale, query: "%#{query}%")
  end

  attr_reader :current_vendor, :locale, :query
end
