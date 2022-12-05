class DeliveryTimePeriod < ApplicationRecord
  include Authority::Abilities

  belongs_to :delivery_time_slot
  has_many :orders, dependent: :nullify

  validates :from, :to, presence: true

  validate :from_less_to

  scope :ordered, -> { order('from_at asc') }
  scope :actual, ->(current_time) { where('from_at > ?', current_time) }

  delegate :date, :format_date, :vendor_delivery, :vendor_delivery_id, to: :delivery_time_slot

  before_save :set_from_at

  def format_period
    "с #{from.strftime('%H:%M')} по #{to.strftime('%H:%M')}"
  end

  def title
    [format_date, format_period].join(', ')
  end

  def to_s
    title
  end

  private

  def from_less_to
    errors.add(:from, 'От не может быть больше До') if from > to
  end

  def set_from_at
    self.from_at = Time.parse("#{date} #{from}").utc
  end
end
