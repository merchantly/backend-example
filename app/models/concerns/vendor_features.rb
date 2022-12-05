module VendorFeatures
  extend ActiveSupport::Concern

  DEFAULT_MAX_USERS = 2
  TARIFF_FEATURES_LIST = %i[
    feature_export_data
    feature_edit_menu
    feature_package
    feature_coupon
    feature_to_basket_in_list
    feature_delivery_tracking
    feature_blog
    feature_lookbook
    feature_notify_templates
    feature_client_cabinet
    feature_wishlist
    feature_multilanguage
    feature_delivery_service
    feature_moysklad
    feature_order_state
    feature_yandex_market
    feature_torg_mail
    feature_import
    feature_slider
    feature_convead
    feature_domain
    feature_custom_css
    feature_amocrm
  ].freeze

  UNKNOWN_FEATURES_LIST = %i[
    yandex_kassa
    other
    apidoc
    torg_mail
    vkontakte_export
    yandex_market
    facebook
    vkontakte
    export
    disqus
    tasty
    import_yml
    digital_goods
    dashboard
    legal
    delivery
    pay
    products
    subscriptions
    billing
    my_shop
    shop
    goods
    categories
    properties
    dictionaries
    packaging
    tags
    orders
    coupon
    vendor_deliveries
    vendor_payments
    clients
    subscription_emails
    content
    content_pages
    elements
    pages
    blog
    blog_posts
    slider
    lookbook
    lookbooks
    top_banners
    edit_menu
    integrations
    settings
    design
    filter
    common
    domain
    main_page
    files
    mail_templates
    slugs
    sms_log
    members
    style
    translations
    cache
    menu
    order
    footer
    header
    logo
    css
    extra_html
    asset_images
    category
    welcome
    top_banner
    product
    walletone
    pay_pal
    rbk_money
    atol
    starrys
    orange_data
    cloud_kassir
    rfm
    order_conditions
    coupons
    order_operator_filters
    workflow_states
    bitrix24
    commerce_ml
    import_tables
    import_photos
    google_analytics
    yandex_metrika
    sitemap
    slug_redirects
    slug_resources
    robots
    cloud_payments
    life_pay
  ].freeze

  included do
    TARIFF_FEATURES_LIST.each do |feature|
      define_method "#{feature}?" do
        # пока все фичи врублены для всех тарифов 09.04.2018 - 09.07.2018
        # tariff.nil? || (tariff.present? && tariff.send("#{feature}?"))
        true
      end
    end

    # потому что в интеграциях названия отличаются
    alias_method :feature_export?, :feature_export_data?
    alias_method :feature_amo_crm?, :feature_amocrm?
  end

  def feature_max_users
    tariff.present? && tariff.is_a?(Tariff) ? tariff.feature_max_users : Tariff::FEATURE_NO_LIMIT_COUNT
  end

  def feature_max_users_full?
    members.count >= feature_max_users
  end

  def feature_max_products
    tariff.present? && tariff.is_a?(Tariff) ? tariff.feature_max_products : Tariff::FEATURE_NO_LIMIT_COUNT
  end

  def feature_max_products_full?
    # пока все фичи врублены для всех тарифов 09.04.2018 - 09.07.2018
    # products.common.alive.count >= feature_max_products
    false
  end

  def feature?(feature_name)
    is_feature? feature_name
    # Rails.logger.warn "feature_name: #{feature_name}: #{res}"
  end

  def is_feature?(_feature_name)
    # пока все фичи врублены для всех тарифов 09.04.2018 - 09.07.2018
    true

    # return true if $flipper[feature_name].enabled? self

    # feature_method = "feature_#{feature_name}?"

    # if respond_to? feature_method
    #   return public_send feature_method
    # else
    #   unless UNKNOWN_FEATURES_LIST.include? feature_name
    #     Bugsnag.notify "Не существует feature в списке #{feature_name}", metaData: { feature_name: feature_name }
    #   end
    # end

    # true
  end
end
