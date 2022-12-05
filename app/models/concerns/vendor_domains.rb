module VendorDomains
  extend ActiveSupport::Concern
  DOMAIN_PATTERN = Regexp.union(*Settings.available_domain_zones)

  included do
    attr_accessor :_delete_domain

    validates :subdomain,
              presence: true,
              subdomain: true,
              uniqueness: true,
              length: { maximum: 63 }

    validates :subdomain, exclusion: { in: Settings.ignored_subdomains }, if: :will_save_change_to_subdomain?

    validates :suggested_domain,
              custom_domain: true,
              length: { maximum: 253 },
              uniqueness: { allow_blank: true },
              format: { without: DOMAIN_PATTERN }

    validates :domain,
              custom_domain: true,
              length: { maximum: 253 },
              uniqueness: { allow_blank: true },
              format: { without: DOMAIN_PATTERN }

    validate :validate_suggested_domain, if: :will_save_change_to_suggested_domain?

    has_many :domain_aliases, dependent: :destroy
    accepts_nested_attributes_for :domain_aliases, reject_if: :all_blank, allow_destroy: true

    scope :by_subdomain, ->(subdomain)     { where subdomain: subdomain }
    scope :by_domain, ->(domain)           { where domain: domain }
    scope :by_suggested_domain, ->(domain) { where suggested_domain: domain }
    scope :by_domain_alias, ->(domain)     { joins(:domain_aliases).where(domain_aliases: { domain: domain }) }

    before_validation :prepare_domains
    before_save :prepare_domains

    after_save :attach_suggested_domain

    def self.find_by_domain_alias(domain)
      domain = DomainCleaner.unwww domain
      by_domain_alias(SimpleIDN.to_unicode(domain)).first
    end

    def self.find_by_domain(domain)
      domain = DomainCleaner.unwww domain
      # wanna-be.ru.aydamarket.ru => wanna-be.ru
      vendor = by_domain(domain).first

      return vendor if vendor.present?

      redomain = domain.sub ".#{Settings.default_url_options.host}", ''
      return nil if redomain == domain

      by_domain(redomain).first

      # https://bugsnag.com/brandymint/kiiiosk-dot-com/errors/55ead48b687e12feb856d502#stacktrace
      # PG::Errorincomplete multibyte character
    rescue PG::Error => e
      Bugsnag.notify e
      nil
    end

    def self.find_by_suggested_domain(domain)
      # Домена может не быть если зашли по ip
      # https://bugsnag.com/brandymint/kiiiosk-dot-com/errors/5515cd7acf825b739db2fb4b
      domain = DomainCleaner.unwww domain

      vendor = by_suggested_domain(domain).first

      return vendor if vendor.present?

      # wanna-be.ru.aydamarket.ru => wanna-be.ru
      redomain = domain.sub ".#{Settings.default_url_options.host}", ''
      return nil if redomain == domain

      by_suggested_domain(redomain).first
    end

    def self.find_by_request(request)
      vendor = nil

      Settings.domain_zones.each do |zone|
        request.tld_length = zone.split('.').count - 1
        if request.domain == zone
          vendor = Vendor.find_by(subdomain: request.subdomain)
          break
        end
      end
      request.tld_length = Settings.tld_length unless vendor

      vendor || find_by_domain(request.host) || find_by_domain_alias(request.host)
    end

    def self.find_by_host(host)
      return nil if host.blank?

      subdomain = DomainExtractor.extract_subdomain host
      Vendor.find_by_subdomain(subdomain) ||
        Vendor.find_by_domain(host) ||
        Vendor.find_by_domain_alias(host)
    end
  end

  def subdomain
    DomainCleaner.downcase super
  end

  def attach_domain(host)
    return false if suggested_domain.blank?

    if host == suggested_domain
      update_columns domain: suggested_domain, suggested_domain: nil
      enable_https! if Settings::Features.auto_enable_https
      SupportMailer.support_mail(I18n.t('bells.domain_attached.text', domain: domain)).deliver_later!
      bells_handler.add :domain_attached, domain: domain
      true
    else
      Bugsnag.notify 'Попытка привязать домен, которые не suggested', metaData: { host: host, suggested_domain: suggested_domain }
      false
    end
  end

  private

  def attach_suggested_domain
    return unless Settings::Features.auto_attach_domain
    return if suggested_domain.blank?

    attach_domain(suggested_domain)
  end

  def prepare_domains
    self.domain = nil if _delete_domain == 'true'

    self.subdomain = DomainCleaner.prepare_subdomain(subdomain) if subdomain?
    self.domain    = DomainCleaner.prepare(domain) if domain?
    self.suggested_domain = DomainCleaner.prepare(suggested_domain) if suggested_domain?

    self.cached_active_domain = active_domain
  end

  def validate_suggested_domain
    return unless Settings::Features.validate_domain_dns_ip
    return if suggested_domain.blank?

    errors.add :suggested_domain, I18n.t('errors.messages.domain_dns_incorrected') unless DomainChecker.new(suggested_domain).equal_ip?(Settings.dns.ip)
  end
end
