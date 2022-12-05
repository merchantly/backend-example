class Ecr::Branch < ApplicationRecord
  include Archivable
  include Authority::Abilities

  self.table_name = :ecr_branches

  belongs_to :vendor
  belongs_to :cashier, class_name: 'Ecr::Cashier'

  validates :name, presence: true, uniqueness: { scope: :vendor_id }

  scope :ordered, -> { order :name }

  has_many :branch_to_warehouses, class_name: 'Ecr::BranchToWarehouse', foreign_key: :ecr_branch_id
  has_many :warehouses, through: :branch_to_warehouses

  accepts_nested_attributes_for :branch_to_warehouses

  def is_default?
    default?
  end

  def default?
    vendor.default_branch == self
  end
end
