class BankIncomingContractor < ApplicationRecord
  belongs_to :vendor

  validates :contractor_inn, uniqueness: true, allow_nil: true

  def to_s
    vendor.active_domain
  end
end
