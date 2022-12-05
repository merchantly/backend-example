require 'simpleidn'

module VendorUrls
  extend ActiveSupport::Concern

  included do
    before_save :ascii_domain
    before_save :cache_home_url
  end

  def sitemap_url
    "#{public_url}/sitemap.xml.gz"
  end

  def cart_items_url
    home_url + Rails.application.routes.url_helpers.vendor_cart_items_path
  end

  def human_domain
    domain_unicode.presence || subdomain
  end

  def public_api_url
    "#{home_url_without_protocol}/api"
  end

  def operator_api_url
    "#{operator_url}/api"
  end

  def subdomained_public_api_url
    "#{subdomained_url}/api"
  end

  def operator_url(_args = {})
    "#{subdomained_url}/operator"
  end

  def tech_url
    "http://#{subdomained_host}"
  end

  def operator_host
    subdomained_host
  end

  def subdomained_url(params = {})
    a = Addressable::URI.new
    a.host = subdomained_host
    a.scheme = subdomain_protocol
    a.port = ENV['KIOSK_PORT'] if Rails.env.development?

    params = params.compact # делаем compact, чтобы убрать такие случаи как ?locale=&
    a.query_values = params if params.present?

    a.to_s
  end

  # Для поддержки SluggableResource
  def public_path(params = {})
    return '/' if params.empty?

    "/?#{params.to_query}"
  end

  def public_url(params = {})
    home_url params
  end

  def preview_url(params = {})
    public_url params.merge(preview: preview_code)
  end

  def iframe_preview_url(params = {})
    # no_canonical_redirect - чтобы не редиректило на кастомный домен, у которого может и не быть https
    # браузеры блочат http iframe на https странице
    # https://developer.mozilla.org/ru/docs/Security/MixedContent/FixMixedContent
    subdomained_url params.merge no_canonical_redirect: true, preview: preview_code
  end

  def home_url_without_protocol(params = {})
    a = Addressable::URI.new
    a.host = host
    a.query_values = params if params.present?
    a.port = ENV['KIOSK_PORT'] if Rails.env.development? && ENV['KIOSK_PORT'].present?

    a.to_s
  end

  def home_url(params = {})
    a = Addressable::URI.new
    a.host = params.delete(:host).presence || host
    a.scheme = params.delete(:protocol).presence || protocol.to_s
    a.port = ENV['KIOSK_PORT'] if Rails.env.development?

    params = params.compact # делаем compact, чтобы убрать такие случаи как ?locale=&
    a.query_values = params if params.present?

    a.to_s
  end

  def host
    if use_active_domain?
      active_domain
    else
      subdomained_host
    end
  end

  def active_domain
    domain.presence || "#{subdomain || 'unknown'}.#{safe_domain_zone}"
  end

  def safe_domain_zone
    Settings.domain_zones.include?(domain_zone) ? domain_zone : Settings.default_url_options.host
  end

  def subdomained_host
    get_host subdomain
  end

  def get_host(subdom)
    Addressable::URI.parse(
      Rails.application.routes.url_helpers.vendor_root_url(subdomain: (subdom || 'NONAME'.freeze))
    ).host
  end

  def active_domain_unicode
    return if active_domain.blank?

    SimpleIDN.to_unicode active_domain
  end

  def domain_unicode
    return if domain.blank?

    SimpleIDN.to_unicode domain
  end

  def api_url
    Rails.application.routes.url_helpers.api_url(protocol: 'https', port: 443, subdomain: Settings.api_subdomain)
  end

  def pay_pal_payment_callback_url
    api_url + "v1/callbacks/pay_pal/payments/#{id}/notify"
  end

  def yandex_kassa_payment_callback_url
    api_url + "v1/callbacks/yandex/payments/#{id}/notify"
  end

  def yandex_kassa_check_callback_url
    api_url + "v1/callbacks/yandex/payments/#{id}/check"
  end

  def rbk_money_payment_callback_url
    api_url + "v1/callbacks/rbk_money/payments/#{id}/notify"
  end

  def allow_https?
    return false unless Rails.env.production?
    return true if enable_custom_domain_https?

    if domain.present?
      domain == https_custom_domain
    else
      Settings.https.allow_domain_zones.include?(safe_domain_zone)
    end
  end

  def protocol
    allow_https? ? :https : :http
  end

  def subdomain_protocol
    Settings.subdomain_protocol
  end

  private

  def use_active_domain?
    (Rails.env.production? && !Settings[:is_beta]) || Rails.env.test?
  end

  def ascii_domain
    self.domain = SimpleIDN.to_ascii domain if domain.present?
    self.suggested_domain = SimpleIDN.to_ascii suggested_domain if suggested_domain.present?
  end

  def cache_home_url
    self.cached_home_url = home_url
  end
end
