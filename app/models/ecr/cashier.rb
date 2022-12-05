class Ecr::Cashier < ApplicationRecord
  include Archivable
  include Authority::Abilities

  self.table_name = :ecr_cashiers

  belongs_to :vendor
  has_one :branch, class_name: 'Ecr::Branch'
  has_one :account, class_name: 'OpenbillAccount', as: :reference
  has_one :vendor_payment
  has_many :drawers, class_name: 'Ecr::Drawer'

  has_many :daily_reports, class_name: 'Ecr::DailyCashierReport'

  validates :name, presence: true, uniqueness: { scope: :vendor_id }

  scope :ordered, -> { order :name }
  scope :available_for_payment, ->(payment) { left_outer_joins(:vendor_payment).where(vendor_payments: { id: [nil, payment.id] }) }

  after_create :create_accounts

  delegate :amount, to: :account

  def is_default?
    default?
  end

  def default?
    vendor.default_cashier == self
  end

  def all_documents
    Ecr::Document.by_any_cashier_id id
  end

  def open_drawer
    @open_drawer ||= drawers.find_by state: :opened
  end

  def to_s
    name
  end

  private

  def create_accounts
    create_account(
      category_id: Billing::ECR_VENDOR_CASHIERS_CATEGORY_ID,
      key: "vendor-cashier-#{id}-account",
      details: "vendor cashier #{id} account",
      amount_currency: Money.default_currency.iso_code
    )
  end
end
