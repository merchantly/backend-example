class ClientOccupation < ApplicationRecord
  belongs_to :vendor

  validates :name, presence: true, uniqueness: { scope: :vendor_id }
end
