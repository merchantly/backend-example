class Ecr::Nomenclature < ApplicationRecord
  include Authority::Abilities
  include PgSearch::Model
  include Archivable

  self.table_name = :ecr_nomenclatures

  belongs_to :vendor
  belongs_to :quantity_unit
  belongs_to :product_vat_group

  has_many :products, dependent: :nullify
  has_many :product_items, dependent: :nullify

  has_many :warehouse_cells, class_name: 'Ecr::WarehouseCell', dependent: :destroy
  has_many :warehouses, through: :warehouse_cells
  has_many :branch_to_warehouses, class_name: 'Ecr::BranchToWarehouse', through: :warehouses

  has_many :warehouse_movements, class_name: 'Ecr::WarehouseMovement', dependent: :destroy

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :barcode, uniqueness: { scope: %i[vendor_id archived_at] }, length: { minimum: Settings.barcode_min_length, maximum: Settings.barcode_max_length }, allow_blank: true
  validates :ean, numericality: { only_integer: true }, uniqueness: { scope: :vendor_id }, length: { maximum: Settings.ean_max_length }, allow_blank: true

  scope :ordered, -> { order quantity: :desc }

  scope :in_stock, -> { where('ecr_nomenclatures.quantity > 0') }
  scope :out_stock, -> { where(ecr_nomenclatures: { quantity: 0 }) }

  monetize :purchase_price_cents,
           as: :purchase_price,
           allow_nil: true,
           numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

  pg_search_scope :by_query,
                  against: %i[title],
                  associated_against: {
                    products: :cached_title_translations,
                    product_items: :article
                  },
                  using: {
                    tsearch: { dictionary: 'russian' }
                  }

  before_validation :set_barcode

  def alive?
    products.map(&:alive?).reduce(:|)
  end

  def name
    title
  end

  def name_with_quantity
    "#{name} #{humanized_quantity}"
  end

  def vat
    return product_vat_group.vat if product_vat_group.present?

    super || vendor.default_product_vat_group.try(:vat)
  end

  def update_quantity!
    update! quantity: warehouse_cells.sum(:quantity)
  end

  def update_reserve_quantity!
    update! reserve_quantity: warehouse_cells.sum(:reserve_quantity)
  end

  def movements_empty?
    warehouse_movements.empty?
  end

  def products_and_items_empty?(except: nil)
    case except
    when Product
      return true if product_item_ids.present?

      (product_ids - [except.id]).empty?
    when ProductItem
      return true if product_ids.present?

      (product_item_ids - [except.id]).empty?
    when NilClass
      (product_ids + product_item_ids).empty?
    else
      raise "Unknown #{except}"
    end
  end

  def update_purchase_price!(warehouse_movement)
    update! purchase_price: (total_purchase_price + warehouse_movement.total_purchase_price) / (quantity + warehouse_movement.quantity)
  end

  def total_purchase_price
    purchase_price.to_money * quantity
  end

  def barcode_image_url
    Rails.application.routes.url_helpers.operator_ecr_barcode_path(barcode, format: :png)
  end

  def free_quantity
    quantity - reserve_quantity
  end

  def update_ordering!
    products.each(&:update_ordering!)
    product_items.each(&:update_ordering!)
  end

  def regenerate_barcode!
    update barcode: generate_barcode
  end

  private

  def set_barcode
    if barcode.present?
      return unless will_save_change_to_barcode?

      vendor.nomenclatures.find_by(barcode: barcode, is_auto_barcode: true).try(:regenerate_barcode!)

      self.barcode = barcode
      self.is_auto_barcode = false
    else
      self.barcode = generate_barcode(proposed_value: id.to_s)
      self.is_auto_barcode = true
    end
  end

  def generate_barcode(proposed_value: nil)
    current_barcode = proposed_value.presence || random_barcode

    count = 0
    while vendor.nomenclatures.find_by_barcode(current_barcode).present?
      current_barcode = random_barcode
      count += 1

      raise 'I can not generate a barcode' if count > 100
    end

    current_barcode
  end

  def random_barcode
    SecureRandom.hex(Settings.barcode_max_length / 2)
  end
end
