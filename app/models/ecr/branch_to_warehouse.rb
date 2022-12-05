class Ecr::BranchToWarehouse < ApplicationRecord
  self.table_name = :ecr_branch_to_warehouses

  belongs_to :branch, class_name: 'Ecr::Branch', foreign_key: :ecr_branch_id
  belongs_to :warehouse
end
