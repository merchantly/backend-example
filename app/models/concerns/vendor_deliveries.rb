module VendorDeliveries
  extend ActiveSupport::Concern

  included do
    has_many :vendor_deliveries, dependent: :destroy
    has_many :order_deliveries, through: :orders
  end

  def default_delivery_type
    available_delivery_types.first
  end

  def available_delivery_types
    vendor_deliveries.alive.ordered
  end

  def available_delivery_agents
    [OrderDeliveryCSE.name, OrderDeliveryEMS.name, OrderDeliveryPickup.name]
  end

  def delivery_cities
    DeliveryCity.where(delivery_id: vendor_deliveries.pluck(:id))
  end
end
