class VendorSmsLogEntity < ApplicationRecord
  include Authority::Abilities

  belongs_to :vendor

  scope :ordered,   -> { order 'id desc' }
  scope :success,   -> { where is_success: true }
  scope :by_created_at, ->(beginning_of_month, end_of_month) { where('created_at >= ? AND created_at <= ?', beginning_of_month, end_of_month) }
  scope :by_month, ->(month) { by_created_at month.beginning_of_month, month.end_of_month }
  scope :free, -> { where free: true }
  scope :not_free, -> { where free: false }

  scope :search_by_query, ->(query) { where "message like ? OR array_to_string(phones,' ') like ?", "%#{query}%", "%#{query}%" }

  validates :is_success, inclusion: { in: [true, false] }
  validates :sms_count, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  before_update do
    raise 'Нельзя изменять'
  end

  before_destroy do
    raise 'Нельзя удалить'
  end

  before_create do
    vendor.update_attribute :sms_count, vendor.sms_count - sms_count if vendor.present?

    true
  end
end
