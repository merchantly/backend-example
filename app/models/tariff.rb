# тарифы вендоров
class Tariff < ApplicationRecord
  include Archivable
  include RankedModel
  # для числовых фич(например кол-во сотрудников), считается без ограничений
  FEATURE_NO_LIMIT_COUNT = 999_999_999

  # фичи которые мы будем отображать в списке для вендора
  # при выборе тарифа
  # некоторые - фейковые, т.е. не существуют в бд т.к. доступны всем
  FEATURES_FOR_LIST = %i[
    feature_max_users
    feature_max_products
    feature_walletone
    feature_domain
    feature_pages
    feature_export_data
    feature_yandex_kassa
    feature_coupon
    feature_blog
    feature_lookbook
    feature_multilanguage
    feature_moysklad
    feature_delivery_service
    feature_torg_mail
    feature_amocrm
    feature_edit_menu
    feature_notify_templates
    feature_client_cabinet
    feature_wishlist
    feature_order_state
    feature_import
    feature_convead
    feature_custom_css
  ].freeze

  INTEGRATION_FEATURES = %i[
    walletone
    torg_mail
    yandex_kassa
    moysklad
    amocrm
    instagram
    convead
    yandex_market
    rbk_money
  ].freeze

  validates :title, :sms_price, :link_app_disable_price, presence: true

  has_many :vendors, dependent: :nullify
  has_many :published_vendors, -> { published }, class_name: 'Vendor'

  scope :ordered, -> { rank :row_order }
  scope :for_choose, -> { alive.where is_show_in_choose: true }
  scope :unchangable, -> { where can_change: false }

  ranks :row_order

  monetize :link_app_disable_price_cents,
           as: :link_app_disable_price,
           with_model_currency: :link_app_disable_price_currency,
           allow_nil: true,
           numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

  monetize :sms_price_cents,
           as: :sms_price,
           with_model_currency: :sms_price_currency,
           allow_nil: true,
           numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }
  monetize :month_price_cents,
           as: :month_price,
           with_model_currency: :month_price_currency,
           allow_nil: true,
           numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

  def enabled_features
    FEATURES_FOR_LIST.select do |feature|
      # если у тарифа нет метода для фичи значит она фейковая - выводим
      feature_enable?(feature.to_s.gsub('feature_', '')) && (!respond_to?(feature) || try(feature))
    end
  end

  def edit_features
    attributes.keys.select do |key|
      if key =~ /^feature_(.+)/
        feature = Regexp.last_match(1).to_sym

        feature_enable?(feature)
      else
        false
      end
    end
  end

  def feature_enable?(feature)
    if INTEGRATION_FEATURES.include? feature.to_sym
      IntegrationModules.enable? feature.to_sym
    else
      Settings.ignore_features.exclude?(feature.to_s)
    end
  end

  def to_s
    "#{title} [#{id}]"
  end
end
