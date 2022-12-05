module ProductsPerPage
  def index_products_per_page
    vendor.theme.category_product_columns * vendor.theme.category_product_rows
  end
end
