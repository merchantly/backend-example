class SaleGraphEntity < ApplicationRecord
  validates :date, uniqueness: true

  scope :ordered, -> { order :date }
end
