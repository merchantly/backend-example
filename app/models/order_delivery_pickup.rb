class OrderDeliveryPickup < OrderDelivery
  after_create :set_state, :set_expires_at

  def self.model_name
    superclass.model_name
  end

  def selfdelivery?
    true
  end

  def support_agents?
    false
  end

  private

  def set_state
    not_needed!
  end

  def set_expires_at
    return if delivery_type.auto_cancel_period_days.nil?

    update_column :expires_at, (Time.zone.now + delivery_type.auto_cancel_period_days.days)
  end
end
