module VendorTariff
  extend ActiveSupport::Concern

  included do
    belongs_to :tariff, counter_cache: true

    scope :with_tariff,        -> { joins(:tariff) }
    scope :without_tariff,     -> { where tariff_id: nil }

    scope :need_to_pay,        ->(date = Date.current) { where 'paid_to IS NULL OR paid_to <= ?', date.to_date }
    scope :working_to_expired, ->(date = Date.current) { where 'working_to IS NOT NULL AND working_to < ?', date.to_date }
    scope :working,            ->(date = Date.current) { where 'working_to IS NOT NULL AND working_to >= ?', date.to_date }

    before_save do
      self.working_to = paid_to if paid_to.present? && (working_to.nil? || working_to < paid_to)
      self.published_since = Time.zone.now if published_since.nil? && is_published?
    end
  end

  def is_working?
    working_to <= Date.current
  end
end
