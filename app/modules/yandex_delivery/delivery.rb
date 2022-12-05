module YandexDelivery
  class Delivery < ApplicationRecord
    CURRENCY = 'RUB'.freeze

    self.table_name = :yandex_deliveries

    belongs_to :vendor_delivery

    has_many :delivery_locations, class_name: 'YandexDelivery::DeliveryLocation', foreign_key: 'yandex_delivery_id', dependent: :destroy
    has_many :orders, dependent: :nullify, foreign_key: 'yandex_delivery_id'

    def title
      @title = tariff_name
      @title << ", #{cost} р."
      @title << ", #{delivery_dates.join(', ')}"
    end

    def price
      Money.new (cost * 100), CURRENCY
    end

    private

    def delivery_dates
      delivery_date.map do |date|
        I18n.l Date.parse(date), format: '%d %B'
      end
    end
  end
end
