class ProductsMerger
  # @param scope of products
  #
  def initialize(vendor)
    raise 'Must be a vendor' unless vendor.is_a? Vendor

    @vendor = vendor
  end

  def merge!(products)
    raise ManyUnionsError if products.unions.many?
    raise ProductsWithOptionsError if products.map(&:items).select(&:present?).many?

    return unless products.any?

    Product.transaction do
      products.lock
      merge_products products
    end
  end

  private

  attr_reader :vendor

  def merge_products(products)
    union_counts = products.group(:product_union_id).count
    unions = union_counts.keys + products.unions.pluck(:id)
    uniq_unions = unions.compact.uniq

    # Объединение с найбольшим числом товаров
    union_id = uniq_unions.min { |a, b| b[1] <=> a[1] }

    if union_id.present?
      union = vendor.products.find union_id
      raise "Union #{union_id} is not ProductUnion" unless union.is_a? ProductUnion
    end

    # Каждый товар принадлежит к однму и тому-же объединению
    if unions.compact.count == products.count && uniq_unions.one? && union.present?
      return union
    end

    # TODO Сломан. Добавляет товары дважды
    # validate_products! products, union

    products_to_merge = products

    union ||= products.unions.first

    products_to_merge = products.where.not(id: union.id) if union.present?

    if union.blank?
      categories_ids = products.map(&:category_ids).flatten.uniq

      union = vendor.product_unions.create!(
        category_ids: categories_ids,
        title: products.first.title
      )
    end

    raise MaximumUnionsError if union.products.count + products_to_merge.count > vendor.max_products_in_union

    union.products << products_to_merge

    union
  end

  def validate_products!(products, union = nil)
    ps = (products.to_a + Array(union.try(:products))).compact
    raise DifferentPricesError if ps.map(&:actual_price).uniq.many?
  end

  DifferentPricesError = Class.new StandardError
  ManyUnionsError = Class.new StandardError
  MaximumUnionsError = Class.new StandardError
  ProductsWithOptionsError = Class.new StandardError
end
