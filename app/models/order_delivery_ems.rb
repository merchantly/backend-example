class OrderDeliveryEMS < OrderDelivery
  def self.model_name
    superclass.model_name
  end

  def tracking_url
    'http://www.emspost.ru/ru/tracking/'
  end

  def get_state(force = true)
    return unless external_id?

    Rails.cache.fetch "delivery_ems:#{external_id}", force: force do
      EMS::DeliveryState.new(self).get_state
    end
  end

  protected

  def cancel; end
end
