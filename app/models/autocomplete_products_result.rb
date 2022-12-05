class AutocompleteProductsResult
  include Virtus.model struct: true
  attribute :items, Product

  delegate :total_count, to: :items

  def page
    items.current_page
  end
end
