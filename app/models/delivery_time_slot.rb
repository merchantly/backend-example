class DeliveryTimeSlot < ApplicationRecord
  include Authority::Abilities

  belongs_to :vendor_delivery
  has_many :delivery_time_periods

  validates :date, presence: true, uniqueness: { scope: :vendor_delivery_id }

  accepts_nested_attributes_for :delivery_time_periods, reject_if: :all_blank, allow_destroy: true

  scope :ordered, -> { order date: :asc }

  def format_date
    I18n.l date, format: '%d %B'
  end
end
