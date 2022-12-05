class ProductUnion < Product
  include ProductUnionPrices
  include ProductUnionImages

  validate :validate_number_of_products

  # Когда подтовары все кладут в архив, product_union
  # тоже имеет смысл автоматом ложить в архив
  # и на оборот
  before_save :update_statuses_from_products

  before_save if: :product_union_id do
    raise "Subunioning is permitted #{id}"
  end

  def vat
    0
  end

  def self.model_name
    superclass.model_name
  end

  def is_union
    true
  end

  def custom_attributes
    all_custom_attributes
  end

  def good_custom_attributes
    []
  end

  def goods_include_me(scope = nil)
    goods(scope)
  end

  def stock_linked?
    false
  end

  def has_any_sales
    super || products.alive.select(&:is_sale).any?
  end

  def total_quantity
    total = nil

    products.sellable(vendor).viewable.map(&:total_quantity).each do |quantity|
      unless quantity.nil?
        total ||= 0.0
        total += quantity
      end
    end

    return nil if total.nil?

    total.to_e
  end

  # Сомнительная операция.
  # TODO Лучше предотвратить вызов этого метода для ProductUnion вообще
  def quantity_unit
    products.first.try(:quantity_unit) || default_quantity_unit
  end

  def goods(scope = nil)
    base_scope = products.alive.ordered_by_union.map(&:goods).flatten.sort_by { |g| g.is_ordering ? 0 : 1 }
    base_scope = base_scope.reject { |pr| pr.price.nil? || pr.price.zero? }
    base_scope = base_scope.select(&:is_ordering) if scope == :in_stock
    base_scope
  end

  def ordering_as_product_only?
    false
  end

  def remove_from_index?
    super || !products.alive.exists?
  end

  def restore!(include_products: true)
    transaction do
      products.each(&:restore!) if include_products
      super()
    end
  end

  def archive!(include_products: true)
    transaction do
      products.alive.each(&:archive!) if include_products
      super()
    end
  end

  def touched_product
    self.data = all_data
    save
  end

  private

  def validate_number_of_products
    errors.add(:product, I18n.t('activerecord.errors.product_union.maximum', max: vendor.max_products_in_union)) if products.size > vendor.max_products_in_union
  end

  def all_data
    all_custom_attributes
      .map(&:as_data)
      .each_with_object({}) { |a, o| o.merge! a }
  end

  def update_statuses_from_products
    return if new_record?

    if alive?
      archive! include_products: false if products.any? && products.alive.empty?
    elsif products.alive.any?
      restore! include_products: false
    end

    true
  end
end
