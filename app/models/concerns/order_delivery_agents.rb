module OrderDeliveryAgents
  MODULE_MAPPING = {
    cse: OrderDeliveryCSE,
    ems: OrderDeliveryEMS,
    redexpress: OrderDeliveryRedexpress,
    pickup: OrderDeliveryPickup,
    other: OrderDeliveryOther,
    digital: OrderDeliveryDigital,
    russian_post: OrderDeliveryRussianPost,
    yandex_delivery: OrderDeliveryYandex,
    cdek_delivery: OrderDeliveryCdek,
    aramex: OrderDeliveryAramex
  }.freeze

  def agents
    [
      OrderDeliveryCSE,
      OrderDeliveryEMS,
      OrderDeliveryRedexpress,
      OrderDeliveryPickup,
      OrderDeliveryOther,
      OrderDeliveryDigital,
      OrderDeliveryRussianPost,
      OrderDeliveryYandex,
      OrderDeliveryCdek,
      OrderDeliveryAramex
    ]
  end

  def available_agents
    return [] unless IntegrationModules.deliveries.is_a? Array

    IntegrationModules.deliveries.map { |delivery| MODULE_MAPPING[delivery.to_sym] }.compact
  end
end
