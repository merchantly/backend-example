module OrderValidations
  extend ActiveSupport::Concern
  COMMENT_LENGTH = 500
  HOUSE_REGEXP = /^\d+([А-Я]|[a-я]|[A-Z]|[a-z])*$/.freeze # 5, 5A, 5а

  included do
    include MaxOrderItemsCountValidation

    validates :delivery_type_id, presence: true

    validates :country_code,     presence: true, if: :require_country_code?
    validates :address,          presence: true, if: :require_address?, address: true
    validates :city_title,       presence: true, if: :require_city_title?
    validates :delivery_city_id, presence: true, inclusion: { in: proc { |order| order.vendor.delivery_cities.pluck(:id) } }, if: :require_delivery_city?
    validates :pickup_point_id,  presence: true, inclusion: { in: proc { |order| order.delivery_city.present? ? order.delivery_city.pickup_points.pluck(:id) : [] } }, if: :require_pickup_point?

    validates :region, presence: true, if: :is_separate_address
    validates :street, presence: true, if: :is_separate_address
    validates :house,  presence: true, if: :is_separate_address
    validates :room,   presence: true, if: :is_separate_address
    validates :postal_code, presence: true, if: :is_separate_address

    validates :first_name, presence: true, if: :is_separate_name, name: true
    validates :second_name, presence: true, if: :is_separate_name, name: true
    validates :patronymic, presence: true, if: :is_separate_name

    validates :name,             presence: true, length: { maximum: 255 }, if: :require_name?, name: true
    validates :payment_type_id,  presence: true

    # TODO: как-то поменять обратно на string
    validates :comment, length: { maximum: COMMENT_LENGTH }

    validates :yandex_delivery_id, presence: true, if: :require_yandex_delivery?
    validates :cdek_delivery_id, presence: true, if: :require_cdek_delivery?

    validates :delivery_time_period_id, presence: true, if: :require_delivery_time_period?

    validates :country_code, inclusion: { in: CountryService.all_codes }, allow_blank: true

    validate :validate_house

    validates :vendor, presence: true
    validates :phone, presence: true, phone: true, if: :require_phone?
    validates :email, presence: true, if: :require_email?

    validate :validate_payment_type, on: :create, if: :payment_type_id

    delegate :require_country_code?, :require_address?, :is_separate_address, :is_separate_name,
             :require_delivery_city?, :require_pickup_point?, :is_yandex_delivery?, :is_cdek_delivery?, :require_delivery_time?,
             to: :delivery_type, allow_nil: true
  end

  protected

  def require_phone?
    return false if source == OrderSource::SOURCE_OFFLINE

    email.blank?
  end

  def require_email?
    return true if has_any_digital_goods?
    return false if source == OrderSource::SOURCE_OFFLINE

    phone.blank?
  end

  private

  def require_name?
    return false if source == OrderSource::SOURCE_OFFLINE
    return false if is_separate_name

    true
  end

  def require_address?
    return false if source == OrderSource::SOURCE_OFFLINE

    delivery_type.require_address? if delivery_type.present?
  end

  def require_city_title?
    return false if source == OrderSource::SOURCE_OFFLINE

    delivery_type.require_city_title? if delivery_type.present?
  end

  def validate_house
    return if house.blank?

    errors.add :house, I18n.vt('errors.order.house') unless HOUSE_REGEXP.match(house)
  end

  def require_yandex_delivery?
    # яндекс доставки очищаются, чтобы не засорять базу
    # все инфо сохраняется в yandex_delivery_title
    is_yandex_delivery? && yandex_delivery_title.blank?
  end

  def require_cdek_delivery?
    # СДЭК доставки очищаются, чтобы не засорять базу
    # все инфо сохраняется в cdek_delivery_title
    is_cdek_delivery? && cdek_delivery_title.blank?
  end

  def require_delivery_time_period?
    require_delivery_time? && delivery_time_title.blank?
  end

  def validate_payment_type
    errors.add :payment_type_id, I18n.t('errors.order.unavailable_payment') unless delivery_type.available_payment? payment_type
  end
end
