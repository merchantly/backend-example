class OpenbillService < ApplicationRecord
  SERVICES = Billing::SERVICES.keys

  belongs_to :account, class_name: 'OpenbillAccount'
  has_many :vendor_services, dependent: :delete_all
  has_many :openbill_transactions

  validates :title, uniqueness: true

  def find_by_key!(key)
    account_id = Billing::SERVICES[key] || raise("Не найден сервис с ключем #{key}")
    find_by(account_id: account_id) || raise("Не найден сервис с ключем #{key} и счетом #{account_id}")
  end
end
