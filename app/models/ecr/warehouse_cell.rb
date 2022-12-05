class Ecr::WarehouseCell < ApplicationRecord
  self.table_name = :ecr_warehouse_cells

  belongs_to :warehouse
  belongs_to :nomenclature, class_name: 'Ecr::Nomenclature'

  has_many :branch_to_warehouses, class_name: 'Ecr::BranchToWarehouse', through: :warehouse, source: :branch_to_warehouses
  has_many :branches, through: :branch_to_warehouses, class_name: 'Ecr::Branch'

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reserve_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :in_stock, -> { where('quantity > 0') }
  scope :in_sale, -> { where('quantity - reserve_quantity > 0') }

  delegate :product, :product_item, :quantity_unit, to: :nomenclature

  def free_quantity
    quantity - reserve_quantity
  end

  after_save do
    nomenclature.update_quantity!
    nomenclature.update_reserve_quantity!
  end
end
