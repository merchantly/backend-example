class VendorGroup < ApplicationRecord
  include MoyskladEntity
  include Archivable

  scope :ordered, -> { order :name }

  validates :name, presence: true

  belongs_to :vendor

  def to_s
    name
  end
end
