class ExternalDevice < ApplicationRecord
  include Authority::Abilities

  belongs_to :vendor

  scope :ordered, -> { order(:name) }

  validates :name, uniqueness: { scope: :vendor_id }, presence: true
end
