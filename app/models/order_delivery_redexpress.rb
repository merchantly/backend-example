class OrderDeliveryRedexpress < OrderDelivery
  def get_state(force = true)
    Rails.cache.fetch "delivery_redexpress:#{tracking_id}", force: force do
      Redexpress::DeliveryState.new(self).get_state
    end
  end

  def self.model_name
    superclass.model_name
  end

  def tracking_url
    'http://www.redexpress.ru/ru/bonus/CargoInfo/'
  end

  def tracking_id
    buff = "#{vendor.w1_merchant_id}:#{order.external_id}"

    buff.sub! '-dev', '' if Rails.env.development?

    buff
  end
end
