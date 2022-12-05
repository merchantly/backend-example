class OrderDeliveryAramex < OrderDelivery
  serialize :tracking_state, Aramex::Entity::TrackerResponse

  def self.model_name
    superclass.model_name
  end

  def delivery
    AramexWorker.perform_async order_id
  end

  def cancel_with_error!(error)
    cancel!
    update! error: error
  end

  def can_start_delivery?
    true
  end

  def tracking_url
    return if tracking_id.blank?

    "https://www.aramex.com/track/results?mode=0&ShipmentNumber=#{tracking_id}"
  end

  def update_tracking_state
    get_state true
  end

  def get_state(force = true)
    return if tracking_id.blank?

    return tracking_state if tracking_state.present? && !force

    new_state = Aramex::DeliveryState.new(order_delivery: self).get_state

    if tracking_state.update_date_time != new_state.update_date_time
      update! tracking_state: new_state

      order.admin_comments.create! body: I18n.t('order_delivery_tracking_comments.new_state', state: new_state), namespace: :admin
    end

    new_state
  end
end
