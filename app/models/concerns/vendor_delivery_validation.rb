module VendorDeliveryValidation
  extend ActiveSupport::Concern

  REQUIRED_DIMENSIONS_AGENTS = %w[OrderDeliveryYandex OrderDeliveryAramex OrderDeliveryCdek].freeze
  REQUIRED_DEFAULT_WEIGHT_AGENTS = %w[OrderDeliveryRussianPost OrderDeliveryYandex OrderDeliveryAramex OrderDeliveryCdek].freeze
  REQUIRED_SEPARATE_ADDRESS_AGENTS = %w[OrderDeliveryRussianPost OrderDeliveryAramex].freeze
  REQUIRED_SEPARATE_NAME_AGENTS = %w[OrderDeliveryRussianPost].freeze
  REQUIRED_COUNTRY_CODE_AGENTS = %w[OrderDeliveryAramex].freeze

  included do
    validates :title, presence: true, length: { maximum: 200 }

    validates :delivery_agent_type, presence: true, inclusion: { in: OrderDelivery.available_agents.map(&:name) }
    validates :auto_cancel_period_days, numericality: { greater_than_or_equal_to: 1 }, allow_blank: true

    validates :default_weight_gr, presence: true, if: :required_default_weight?
    validates :default_length, :default_width, :default_height, presence: true, if: :required_dimensions?

    validates :is_separate_address, presence: true, if: :required_separate_address?
    validates :is_separate_name, presence: true, if: :required_separate_name?

    validates :russian_post_token, :russian_post_key, :russian_post_mail_category, :russian_post_mail_type, presence: true, if: :is_russian_post?

    validates :yandex_city_from, :yandex_delivery_type, presence: true, if: :is_yandex_delivery?

    validates :yandex_search_delivery_list_api_key, :yandex_city_from, :yandex_delivery_type, :yandex_delivery_sender_id, :yandex_delivery_client_id, presence: true, if: :is_yandex_delivery?

    validates :aramex_username, :aramex_password, :aramex_version, :aramex_account_number, :aramex_account_pin, :aramex_account_entity, :aramex_account_country_code, presence: true, if: :required_aramex_data?

    validates :shipper_country_code, :shipper_address, :shipper_city, :shipper_postal_code, :shipper_name, :shipper_phone, :shipper_email, presence: true, if: :required_shipper_data?

    validates :cdek_sender_city_id, :cdek_sender_city_post_code, presence: true, if: :is_cdek_delivery?
    validates :cdek_tariff_id, presence: true, inclusion: { in: Cdek::TARIFFS.map(&:second) }, if: :is_cdek_delivery?

    validates :cdek_login, :cdek_password, presence: true, if: :required_cdek_auth?

    validates :require_country_code, presence: true, if: :required_country_code?

    validates :default_country_code, inclusion: { in: CountryService.all_codes }, allow_blank: true

    before_validation do
      self.is_separate_address = true if required_separate_address?
      self.is_separate_name = true if required_separate_name?

      if required_country_code?
        self.require_country_code = true
        self.default_country_code = Settings.default_delivery_country_code
      end
    end
  end

  def require_delivery_city?
    alive_cities_count.positive?
  end

  def require_pickup_point?
    alive_pickup_points_count.positive?
  end

  def require_city_title?
    ((require_address? && city_title.blank?) || is_separate_address)
  end

  def require_address?
    !is_digital_only? && !selfdelivery? && !require_pickup_point? && !is_separate_address && !cdek_delivery_pickup_point?
  end

  def require_delivery_time?
    DeliveryTimeResolver.perform(vendor_delivery: self, current_time: Time.zone.now).present?
  end

  private

  def required_default_weight?
    REQUIRED_DEFAULT_WEIGHT_AGENTS.include? delivery_agent_type
  end

  def required_separate_address?
    REQUIRED_SEPARATE_ADDRESS_AGENTS.include? delivery_agent_type
  end

  def required_separate_name?
    REQUIRED_SEPARATE_NAME_AGENTS.include? delivery_agent_type
  end

  def required_dimensions?
    REQUIRED_DIMENSIONS_AGENTS.include? delivery_agent_type
  end

  def required_country_code?
    REQUIRED_COUNTRY_CODE_AGENTS.include? delivery_agent_type
  end

  def required_shipper_data?
    is_aramex?
  end

  def required_aramex_data?
    is_aramex? && !aramex_is_test
  end
end
