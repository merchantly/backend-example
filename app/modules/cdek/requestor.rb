class Cdek::Requestor
  include Virtus.model
  include AutoLogger

  DELIVERIES_HOST = 'https://integration.cdek.ru'.freeze
  DELIVERIES_POINT = 'pvzlist/v1/json'.freeze

  CALCULATOR_HOST = 'http://api.cdek.ru'.freeze
  CALCULATOR_POINT = 'calculator/calculate_price_by_json.php'.freeze

  CityIdNotFound = Class.new StandardError
  CityPostCodeNotFound = Class.new StandardError
  DeliveryCostError = Class.new StandardError

  attribute :search_city, String
  attribute :vendor_delivery, VendorDelivery

  delegate :cdek_tariff_id, :cdek_sender_city_post_code, :cdek_sender_city_id, :cdek_login, :cdek_password, to: :vendor_delivery

  def deliveries
    build_deliveries.compact.sort_by(&:cost)
  end

  private

  def build_deliveries
    if vendor_delivery.cdek_delivery_pickup_point?
      cities.map { |city| pickup_points(city) }.flatten
    elsif vendor_delivery.cdek_delivery_home?
      cities.map { |city| home_delivery(city) }
    else
      raise "Unknown cdek_tariff_id #{cdek_tariff_id}"
    end
  end

  def pickup_points(city)
    response = Faraday.get("#{DELIVERIES_HOST}/#{DELIVERIES_POINT}", cityId: city[:id].to_i)

    result = JSON.parse response.body

    return [] if result['pvz'].blank?

    result['pvz'].map do |pvz|
      delivery = Cdek::Delivery.find_by(code: pvz['code'], vendor_delivery: vendor_delivery, vendor_delivery_updated_at: vendor_delivery.updated_at)
      delivery = create_delivery(city, pvz) if delivery.blank?
      delivery
    end
  end

  def home_delivery(city)
    delivery = Cdek::Delivery.find_by(
      city_id: city[:id].to_i,
      vendor_delivery: vendor_delivery,
      vendor_delivery_updated_at: vendor_delivery.updated_at
    )
    delivery = create_delivery(city) if delivery.blank?
    delivery
  end

  def create_delivery(city, pvz = {})
    Cdek::Delivery.create!(
      city_id: city[:id].to_i,
      code: pvz['code'],
      address: pvz['address'],
      work_time: pvz['workTime'],
      cost: delivery_cost(city),
      vendor_delivery: vendor_delivery,
      vendor_delivery_updated_at: vendor_delivery.updated_at,
      city: city[:name],
      tariff_id: cdek_tariff_id,
      country: city[:country],
      obl_name: city[:obl_name]
    )
  rescue CityIdNotFound, CityPostCodeNotFound, DeliveryCostError => e
    logger.error [vendor_delivery.id, search_city, e.to_s].join(',') if e.is_a? DeliveryCostError

    nil
  end

  def cities
    @cities ||= Cdek::Cities.find_by_name(search_city) || raise(CityIdNotFound)
  end

  def delivery_cost(city)
    conn = Faraday.new url: "#{CALCULATOR_HOST}/#{CALCULATOR_POINT}"

    response = conn.get do |req|
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.headers['Accept'] = 'application/json'

      req.body = calculator_params(city).to_json
    end

    result = JSON.parse response.body

    raise DeliveryCostError.new(result.to_s) if result['result'].blank?

    result['result']['price']
  end

  def calculator_params(city)
    params = {
      version: '1.0',
      senderCityId: cdek_sender_city_id,
      senderCityPostCode: cdek_sender_city_post_code,
      tariffId: cdek_tariff_id,
      receiverCityId: city[:id].to_i,
      receiverCityPostCode: city_post_code(city),
      goods: [
        {
          weight: (vendor_delivery.default_weight_gr / 1000.0),
          length: vendor_delivery.default_length,
          width: vendor_delivery.default_width,
          height: vendor_delivery.default_height
        }
      ]
    }

    params.merge! auth_params if cdek_login.present? && cdek_password.present?

    params
  end

  def city_post_code(city)
    raise CityPostCodeNotFound if city[:post_codes].blank?

    city[:post_codes].to_s.split(',').first
  end

  def auth_params
    {
      authLogin: cdek_login,
      secure: secure_password,
      dateExecute: current_date
    }
  end

  def secure_password
    Digest::MD5.hexdigest("#{current_date}&#{cdek_password}")
  end

  def current_date
    @current_date ||= Time.zone.now.to_date.strftime
  end
end
