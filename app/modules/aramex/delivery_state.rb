class Aramex::DeliveryState
  include Virtus.model

  attribute :order_delivery, OrderDelivery

  def get_state
    response = Aramex::Operation::ShipmentTracker.new(order_delivery: order_delivery).perform

    Aramex::Entity::TrackerResponse.new response
  end
end
