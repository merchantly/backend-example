class DeliveryTimeRule < ApplicationRecord
  belongs_to :vendor_delivery

  validates :to, :time, presence: true

  scope :ordered, -> { order('delivery_time_rules.to asc') }
end
