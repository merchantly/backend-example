require 'securerandom'
class Vendor < ApplicationRecord
  include RankedModel
  include Authority::Abilities
  include Archivable
  include VendorMoysklad
  include ExistenVendors
  include VendorDomains
  include VendorWorkflowStates
  include VendorUrls
  include VendorW1
  include VendorCategories
  include VendorNotifyContacts
  include VendorPayments
  include VendorDeliveries # должны идти после VendorPayments
  include VendorCurrency
  include VendorDashboard
  include VendorLocator
  include VendorBells::VendorConcerns
  include VendorPackages
  include VendorDestroy
  include VendorStatuses
  include VendorProperties
  include VendorVkontakte
  include VendorRobots
  include TimeScopes
  include SeoFields
  include VendorMoyskladWarehouses
  include VendorEcrWarehouses
  include VendorStatsConcern
  include VendorCatalogsGenerate
  include VendorIntegrations
  include VendorClientWishlistSupport
  include VendorUtm
  include VendorTranslations
  include VendorRelations
  include VendorOperators
  include Vendor::AccountBilling
  include Vendor::PartnerSupport
  include VendorPayOption
  include VendorTariff
  include VendorFeatures
  include FlipperActor
  include VendorArchive
  include VendorRoles
  include Vendor::Services
  include VendorRfmSupport
  include Vendor::FromEmail
  include Vendor::Notify
  include Vendor::AmoCRMSupport
  include VendorClient
  include VendorPriceKinds
  include VendorClientCategories
  include VendorVats
  include RecommendedProducts
  include VendorQuantityUnits
  include VendorTitleTemplates
  include GeoLocation
  include VendorOperatorWarnings
  include VendorCallbacks
  include VendorValidations
  include VendorScopes
  include VendorVatCategory
  include VendorCerts

  strip_attributes

  extend Enumerize
  enumerize :default_product_position, in: %w[first last], default: 'last'
  enumerize :filter_apply_type, in: %w[notice btn], default: 'notice'
  enumerize :vat_calculation_version, in: %w[v1 v2], default: 'v2'

  monetize :first_billing_payment_amount_cents,
           as: :first_billing_payment_amount

  monetize :minimal_price_cents,
           as: :minimal_price,
           allow_nil: false,
           numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

  mount_uploader :logo, VendorLogoUploader
  mount_uploader :desktop_screenshot, SystemUploader
  mount_uploader :mobile_screenshot, SystemUploader
  mount_uploader :invoice_stamp_image, VendorImageUploader
  mount_uploader :torg_mail_catalog, CatalogUploader
  mount_uploader :yandex_catalog, CatalogUploader
  mount_uploader :facebook_catalog, CatalogUploader
  mount_uploader :yandex_turbo_pages, CatalogUploader

  ranks :example_order, column: :as_example_position

  scope :with_https, -> { where.not(https_custom_domain: nil) }

  enumerize :seller_type, in: %w[CRN MOM MLS SAG OTH], default: 'CRN'

  accepts_nested_attributes_for :theme, update_only: true
  accepts_nested_attributes_for :vendor_walletone, update_only: true
  accepts_nested_attributes_for :vendor_email, update_only: true
  accepts_nested_attributes_for :commerce_ml_configuration, update_only: true

  delegate :count, to: :product_images, prefix: true
  delegate :count, to: :products, prefix: true
  delegate :count, to: :orders, prefix: true

  delegate :show_children_products_on_welcome?, to: :theme

  alias_attribute :description, :name
  alias_attribute :logo_text, :name

  translates :title, :contacts, :pre_products_text, :post_products_text, :not_available_content, :legal_name, :legal_address, :legal_city, :inn_text, :receipt_top_text, :receipt_bottom_text, :legal_email_text, :legal_phone_text, :social_media, :legal_street, :legal_region, :legal_province

  def self.subdomain(sd)
    find_by(subdomain: sd)
  end

  def vendor_id
    id
  end

  def enable_https!
    return if domain == https_custom_domain

    update_columns https_custom_domain: domain, enable_https_redirection: true
  end

  def disable_https!
    update_columns https_custom_domain: nil, enable_https_redirection: false
  end

  def to_s
    active_domain_unicode
  end

  def is_template?
    VendorTemplate.where(vendor_id: id).any?
  end

  def is_demo
    key == Secrets.demo_vendor_key
  end

  def invoicer
     Billing::Invoicer.new vendor: self, date: Date.current
  end

  def registered_at
    registration_at
  end

  def max_order_similar_products_count
    [
      custom_max_order_similar_products_count,
      Settings::Order.max_order_similar_products_count
    ].compact.min
  end

  def max_order_items_count
    [
      custom_max_order_items_count,
      Settings::Order.max_order_items_count
    ].compact.min
  end

  def max_orderable_quantity
    max_order_similar_products_count
  end

  def vat
    nil
  end

  def external_id
    id.to_s
  end

  def default_path(params = {})
    Rails.application.routes.url_helpers.vendor_root_path params
  end

  def has_any_goods?
    products.published.alive.any?
  end

  def show_coupon_field?
    coupons.alive.usable.any?
  end

  def cache_key(*args)
    CacheKeyGenerator.perform self, (%i[updated_at translations_updated_at cache_sweeped_at] + args)
  end

  def flush_cache
    touch :cache_sweeped_at
  end

  def invoice_legal_name
    legal_name.presence || host
  end

  def use_coupon_code?
    coupons.alive.any? || promotions.alive.any?
  end

  def use_convead?
    convead_app_key.present?
  end

  def min_and_max_product_prices
    min_price = price_kinds.minimum(:min_product_price_cents)
    max_price = price_kinds.maximum(:max_product_price_cents)

    return unless min_price && max_price

    [
      Money.new(min_price, default_currency),
      Money.new(max_price, default_currency)
    ]
  end

  def inn_blank?
    !inn_present?
  end

  def inn_present?
    translations_field_present?(:inn_text)
  end

  def zatca_enabled?
    seller_type.present? &&
      # tin.present? &&
      inn_present? &&
      translations_field_present?(:legal_street) &&
      translations_field_present?(:legal_name)
  end

  def can_selling?
    return true unless Settings::Features.check_geidea_selling
    return true if legal_country_code.present? && (legal_country_code != 'SA')

    zatca_enabled?
  end
end
