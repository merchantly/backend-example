class Warehouse < ApplicationRecord
  extend Enumerize

  include Authority::Abilities
  include MoyskladEntity
  include Archivable
  include Activable

  belongs_to :vendor

  has_many :warehouse_cells, class_name: 'Ecr::WarehouseCell', dependent: :destroy
  has_many :nomenclatures, class_name: 'Ecr::Nomenclature', through: :warehouse_cells

  has_many :branch_to_warehouses, class_name: 'Ecr::BranchToWarehouse'
  has_many :branches, through: :branch_to_warehouses, foreign_key: :ecr_branch_id

  SOURCE_MOYSKLAD = 'moysklad'.freeze
  SOURCE_ECR = 'ecr'.freeze
  SOURCES = [SOURCE_MOYSKLAD, SOURCE_ECR].freeze

  enumerize :source, in: Warehouse::SOURCES, default: Warehouse::SOURCE_MOYSKLAD, scope: true

  scope :ordered, -> { order :name }

  validates :name, presence: true

  accepts_nested_attributes_for :branch_to_warehouses

  def description
    stock_description
  end

  def name
    buffer = super

    buffer << ' (в архиве)' if archived?
    buffer
  end

  def movements
    Ecr::WarehouseMovement.by_any_warehouse_id id
  end

  def is_default
    default?
  end

  def default?
    vendor.default_warehouse_id == id
  end
end
