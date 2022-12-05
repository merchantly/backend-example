module VendorScopes
  extend ActiveSupport::Concern

  included do
    # Опубликованные заведения
    scope :published, -> { where is_published: true }
    scope :no_published, -> { where is_published: false }
    scope :domained, -> { where.not(domain: nil) }
    # TODO deprecate
    scope :active, lambda {
      joins(:vendor_walletone).where 'vendor_walletones.merchant_id is not null or vendors.stock_success_synced_at is not null or vendors.products_count>0 or vendors.domain is not null'
    }

    scope :shops, -> { not_pre_created.where(templates_count: 0) }

    scope :shops_no_published_and_alive, -> { shops_no_published.alive }
    scope :shops_no_published, -> { shops.no_published }
    scope :shops_published, -> { shops.published }

    scope :sitemaps_obsolete, -> { where 'sitemap_generated_at is null or sitemap_generated_at < products_updated_at' }

    # Отказаться от этихscope в пользу registered
    scope :pre_created, -> { where is_pre_create: true }
    scope :not_pre_created, -> { where is_pre_create: false }

    scope :ordered, -> { order :id }
    scope :with_stock, -> { where.not(stock_success_synced_at: nil) }
    scope :with_orders, -> { where 'orders_count > 1' }
    scope :with_yandex_market, -> { where yandex_market_enabled: true }
    scope :with_torg_mail, -> { where torg_mail_enabled: true }
    scope :with_facebook_catalog, -> { where facebook_catalog_enabled: true }
    scope :with_merchant_token, -> { includes(:vendor_walletone).where.not(vendor_walletones: { merchant_token: nil }) }
    scope :not_approved, -> { includes(:vendor_walletone).where(vendor_walletones: { state: VendorWalletone::STATE_NOT_APPROVED }) }
    scope :approved, -> { includes(:vendor_walletone).where(vendor_walletones: { state: VendorWalletone::STATE_APPROVED }) }
    scope :approve_error, -> { includes(:vendor_walletone).where(vendor_walletones: { state: VendorWalletone::STATE_ERROR_APPROVING }) }
    scope :approve_legacy, -> { includes(:vendor_walletone).where(vendor_walletones: { state: VendorWalletone::STATE_LEGACY }) }
    scope :with_active_partner_coupon, -> { where 'partner_coupon_code IS NOT NULL AND partner_coupon_id IS NOT NULL AND partner_coupon_active_to >= ?', Date.current }
    # обновлен за последний месяц
    scope :updated_last_month, -> { where "#{table_name}.updated_at > ?", Date.current - 1.month }
    scope :registered, -> { where.not registration_at: nil }
    scope :with_screenshots, -> { where.not(desktop_screenshot_width: nil, desktop_screenshot_height: nil) }
    scope :as_examples, -> { with_screenshots.where(use_as_example: true).order('orders_count desc, as_example_position') }
    scope :as_templates, -> { where 'templates_count > 0' }

    # scope :with_done_orders, -> { includes(:orders).where orders: { state: :done } }
  end
end
