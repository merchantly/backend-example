class SimilarProductsService
  def initialize(product, similar_products, count:, is_vendor_show_similar: false, is_product_show_similar: false, auto: false, edit_mode: false)
    @product   = product
    @edit_mode = edit_mode
    @is_vendor_show_similar = is_vendor_show_similar
    @is_product_show_similar = is_product_show_similar
    @similar_products = similar_products
    @auto = auto
    @count = count
  end

  def products
    if !edit_mode && (!is_vendor_show_similar || !is_product_show_similar)
      return []
    end

    similar_cards
  end

  private

  delegate :vendor, to: :product
  attr_reader :product, :auto, :edit_mode, :is_vendor_show_similar, :is_product_show_similar, :similar_products, :count

  def similar_cards
    cards = similar_products.published.limit(count).includes(:slug, items: [:vendor])
    cards = cards.orderable unless vendor.show_out_of_stock_products?

    if (edit_mode || auto) && cards.count < count
      cards += random_similar_cards(count - cards.length)
    end

    cards
  end

  def random_similar_cards(limit)
    filter = VendorProductsFilter.new(
      exclude_by_ids: [product.id, similar_products.map(&:id)].flatten,
      category_id: product.category.try(:id),
      is_published: true,
      order: VendorProductsFilter::ORDER_RANDOM,
      limit: limit
    )

    PublicProductsQuery.new(vendor: vendor, filter: filter).perform
  rescue StandardError => e
    Rails.logger.error e
    Bugsnag.notify e, metaData: { vendor_id: vendor.id, filter: filter }
    []
  end
end
