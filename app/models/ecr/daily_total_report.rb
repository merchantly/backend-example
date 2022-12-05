class Ecr::DailyTotalReport < ApplicationRecord
  self.table_name = 'ecr_daily_total_reports'

  belongs_to :vendor

  validates :date, presence: true, uniqueness: { scope: :vendor_id }

  monetize :net_balance_cents

  scope :ordered, -> { order date: :desc }
  scope :by_date, ->(date) { where date: date }

  before_validation do
    self.net_balance = reports.map(&:net_balance).sum if reports.present?
  end

  private

  def reports
    @reports ||= vendor.daily_cashier_reports.by_date(date)
  end
end
