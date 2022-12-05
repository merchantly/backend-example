module YandexDelivery
  class DeliveryLocation < ApplicationRecord
    scope :ordered, -> { order(:location) }

    self.table_name = :yandex_delivery_locations

    belongs_to :yandex_delivery, class_name: 'YandexDelivery::Delivery'
  end
end
