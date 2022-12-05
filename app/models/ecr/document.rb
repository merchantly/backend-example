class Ecr::Document < ApplicationRecord
  include Authority::Abilities
  include DocumentValidation

  self.table_name = :ecr_documents

  belongs_to :vendor

  has_many :transactions, class_name: 'OpenbillTransaction'

  monetize :amount_cents

  scope :by_any_cashier_id, ->(id) { where('from_cashier_id = ? or to_cashier_id = ? or cashier_id = ?', id, id, id) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where type: (type.is_a?(Array) ? type.map(&:name) : type.name) }

  TYPES = [
    Ecr::SaleDocument,
    Ecr::TransferDocument,
    Ecr::ReceiptDocument,
    Ecr::ExpenseDocument,
    Ecr::RefundDocument
  ].freeze

  def details
    raise 'Not implemented'
  end

  def debit
    raise 'Not implemented'
  end

  def credit
    raise 'Not implemented'
  end

  def self.humanized_type
    I18n.t(name.underscore.tr('/', '_').to_sym, scope: %i[titles ecr_documents])
  end

  def for_table(_current_cashier)
    [self]
  end

  def can_reset?
    false
  end
end
