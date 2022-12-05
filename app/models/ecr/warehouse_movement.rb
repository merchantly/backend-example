class Ecr::WarehouseMovement < ApplicationRecord
  include Authority::Abilities
  include WarehouseMovementValidation

  self.table_name = :ecr_warehouse_movements

  belongs_to :nomenclature, class_name: 'Ecr::Nomenclature', touch: true
  belongs_to :vendor

  TYPES = [
    'Ecr::WarehouseMovementReceipt',
    'Ecr::WarehouseMovementExpense',
    'Ecr::WarehouseMovementTransfer'
  ].freeze

  after_commit on: :create do
    nomenclature.update_ordering!
  end

  validates :type, presence: true, inclusion: { in: Ecr::WarehouseMovement::TYPES }

  scope :by_any_warehouse_id, ->(id) { where('from_warehouse_id = ? or to_warehouse_id = ? or warehouse_id = ?', id, id, id) }

  scope :ordered, -> { order(created_at: :desc) }

  scope :by_type, ->(type) { where type: (type.is_a?(Array) ? type.map(&:name) : type.name) }

  delegate :products, :quantity_unit, to: :nomenclature
  delegate :product_item, to: :nomenclature, allow_nil: true

  before_validation do
    self.vendor ||= nomenclature.vendor
  end

  def self.humanized_type
    I18n.t(name.underscore.tr('/', '_').to_sym, scope: %i[titles warehouse_movement])
  end
end
