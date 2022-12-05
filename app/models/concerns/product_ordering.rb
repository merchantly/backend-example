module ProductOrdering
  extend Enumerize
  extend ActiveSupport::Concern

  included do
    # Можно сделать заказ на товар или его модификацию
    #
    scope :good_ordering, -> { where has_ordering_goods: true }

    before_save :update_ordering
  end

  def has_ordering_goods
    update_ordering unless @ordering_service && @updated_ordering && persisted?
    super
  end

  def ordering_as_product_only?
    ordering_as_product_only
  end

  def ordering_as_product_only
    self.ordering_as_product_only = build_ordering_as_product_only if new_record? && !saved_change_to_ordering_as_product_only?
    super
  end

  def update_ordering!
    update_ordering
    update_columns is_published: is_published, has_ordering_goods: is_ordering, ordering_as_product_only: ordering_as_product_only
  end

  private

  # Товар продается именно как Product,
  # а не по модификациям
  def build_ordering_as_product_only
    # TODO кешировать аттрибут is_stocked (или is_sellable)
    # у items-ов, чтобы не дергать vendor-а какждый раз
    if vendor.order_stocking_only?
      items.viewable.stocked.empty?
    else
      items.viewable.empty?
    end
  end

  def update_ordering
    @updated_ordering = true

    self.ordering_as_product_only = build_ordering_as_product_only
    self.is_published       = is_manual_published
    self.has_ordering_goods = is_ordering
    self.cached_is_run_out  = is_run_out
    self.cached_has_any_sales = has_any_sales
    self.cached_has_price = has_price
    true
  end
end
