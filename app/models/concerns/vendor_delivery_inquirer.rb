module VendorDeliveryInquirer
  def is_yandex_delivery?
    delivery_agent_type == 'OrderDeliveryYandex'
  end

  def is_cdek_delivery?
    delivery_agent_type == 'OrderDeliveryCdek'
  end

  def is_russian_post?
    delivery_agent_type == 'OrderDeliveryRussianPost'
  end

  def is_aramex?
    delivery_agent_type == 'OrderDeliveryAramex'
  end

  def cdek_delivery_pickup_point?
    is_cdek_delivery? && Cdek::PICKUP_POINT_TARIFFS.include?(cdek_tariff_id)
  end

  def cdek_delivery_home?
    is_cdek_delivery? && Cdek::HOME_TARIFFS.include?(cdek_tariff_id)
  end

  def required_cdek_auth?
    is_cdek_delivery? && Cdek::REQUIRED_AUTH_TARIFFS.include?(cdek_tariff_id)
  end
end
