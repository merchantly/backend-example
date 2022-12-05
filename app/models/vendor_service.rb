class VendorService < ApplicationRecord
  DEFAULT_ACTIVATE_DAYS = 0.days

  # Таким способом передаем атрибуты в activities.create!
  attr_accessor :operator, :message

  belongs_to :vendor
  belongs_to :service, class_name: 'OpenbillService'
  belongs_to :tariff

  has_many :activities, class_name: 'VendorServiceActivity'

  before_save do
    raise 'Активность заканчивается раньше оплаченного периода' if available_to.present? && paid_to.present? && available_to < paid_to
  end

  after_save do
    activities.create! message: message, operator: operator, changes: changes
  end

  def paid!(new_paid_to = Time.zone.now, activate_for: DEFAULT_ACTIVATE_DAYS)
    now = Time.zone.now
    update!(
      paid_to: new_paid_to,
      paid_since: paid_since || now,
      paid_at: now,
      available_to: new_paid_to + activate_for,
      available_since: available_since || now,
      activated_at: now
    )
  end

  def prolongate!(for_time:, message:, operator:)
    update!(
      available_to: available_to + for_time,
      message: message,
      operator: operator
    )
  end

  def paid?
    paid_to.present? && paid_to <= Time.zone.now
  end

  def available?
    available_to.present? && available_to <= Time.zone.now
  end

  private

  def data
    attributes.except('vendor_id', 'service_id')
  end
end
