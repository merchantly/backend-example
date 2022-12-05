class CategoryProduct < ApplicationRecord
  include RankedModel

  # Порядок товара в категории
  # TODO переименовать в category_order
  ranks :row_order, with_same: %i[category_id vendor_id], scope: :alive_common_products

  belongs_to :vendor
  belongs_to :category
  belongs_to :product

  has_many :product_prices, through: :product

  after_create :set_default_position

  # важно менять позицию только среди живых сущностей
  # иначе при изминении сортировки будут учитываться мертвые товары
  scope :alive_products, -> { joins(:product).where('products.archived_at IS NULL and products.vendor_id = category_products.vendor_id') }
  scope :common_products, -> { joins(:product).where(products: { product_union_id: nil }) }
  scope :alive_common_products, -> { joins(:product).where('products.archived_at IS NULL and products.product_union_id IS NULL and products.vendor_id = category_products.vendor_id') }

  before_create do
    self.vendor_id ||= product.vendor_id
    self.category_local_id ||= category.local_id
  end

  def set_default_position
    update_attribute :row_order_position, product.vendor.default_product_position.to_sym
  end
end
