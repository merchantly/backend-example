class Ecr::DailyCashierReport < ApplicationRecord
  belongs_to :cashier, class_name: 'Ecr::Cashier'
  belongs_to :vendor

  self.table_name = :ecr_daily_cashier_reports

  monetize :starting_balance_cents, allow_nil: true
  monetize :closing_balance_cents, allow_nil: true
  monetize :net_balance_cents, allow_nil: true

  validates :date, presence: true, uniqueness: { scope: :cashier_id }

  scope :ordered, -> { order date: :desc }
  scope :by_date, ->(date) { where date: date }

  before_validation do
    if drawers.present?
      self.starting_balance = drawers.first.open_actual_balance
      self.closing_balance = drawers.last.close_actual_balance
      self.net_balance = drawers.map(&:close_net_balance).compact.reduce :+
    end
  end

  def drawers
    @drawers ||= cashier.drawers.by_date(date).by_state(Ecr::Drawer::CLOSE_STATE).order(:opened_at)
  end
end
