module YandexDelivery
  class Requestor
    def self.perform(city:, vendor_delivery:, postal_code:)
      new(city: city, vendor_delivery: vendor_delivery, postal_code: postal_code).perform
    end

    def initialize(city:, vendor_delivery:, postal_code:)
      @city = city
      @vendor_delivery = vendor_delivery
      @postal_code = postal_code
    end

    def perform
      YandexDelivery.logger.info "city=#{city} vendor_delivery_id=#{vendor_delivery.id}"

      data = {
        client_id: vendor_delivery.yandex_delivery_client_id, # 46_160,
        sender_id: vendor_delivery.yandex_delivery_sender_id, # 34_277,
        city_from: vendor_delivery.yandex_city_from,
        city_to: city,
        weight: mass_kg,

        length: vendor_delivery.default_length,
        width: vendor_delivery.default_width,
        height: vendor_delivery.default_height,

        delivery_type: vendor_delivery.yandex_delivery_type,
      }

      data[:index_city] = postal_code if vendor_delivery.yandex_delivery_type.post?

      client = YandexDelivery::Client.new(api_key: vendor_delivery.yandex_search_delivery_list_api_key, data: data)

      result = client.perform

      result.map do |delivery|
        yandex_delivery = create_delivery(delivery)

        if delivery['pickupPoints'].present?
          delivery['pickupPoints'].each do |pickup_point|
            yandex_delivery.delivery_locations.create! location: pickup_point['full_address']
          end
        end

        yandex_delivery
      end
    rescue StandardError => e
      YandexDelivery.logger.error "Неудачная попытка city=#{city} vendor_delivery_id=#{vendor_delivery}: #{e.message}"
      raise e
    end

    private

    attr_reader :city, :vendor_delivery, :postal_code

    def mass_kg
      vendor_delivery.default_weight_gr / 1000.0
    end

    def create_delivery(delivery)
      YandexDelivery::Delivery.create!(
        tariff_name: delivery['tariffName'],
        tariff_id: delivery['tariffId'],
        delivery_type: vendor_delivery.yandex_delivery_type,
        cost: delivery['costWithRules'],
        delivery_date: delivery['delivery_date'],
        delivery_intervals: delivery['deliveryIntervals'],
        # payload: delivery,
        city: city,
        vendor_delivery: vendor_delivery
      )
    end
  end
end
