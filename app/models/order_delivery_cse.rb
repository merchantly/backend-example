class OrderDeliveryCSE < OrderDelivery
  def self.model_name
    superclass.model_name
  end

  def tracking_url
    return unless external_id?

    "http://www.cse.ru/track.php?order=order&number=#{external_id}"
  end

  def get_state(force = true)
    return unless external_id?

    Rails.cache.fetch "delivery_cse:#{external_id}", force: force do
      CSE::DeliveryState.new(self).get_state
    end
  end

  protected

  def cancel
    # TODO: cse cancel delivery!
  end
end
