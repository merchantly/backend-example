class BankIncomingExclude < ApplicationRecord
  validates :contractor_inn, presence: true, uniqueness: true
  validates :contractor_name, presence: true
end
