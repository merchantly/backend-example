class DomainAlias < ApplicationRecord
  belongs_to :vendor
  validates :domain, presence: true
  validates :domain,
            custom_domain: true,
            uniqueness: { allow_blank: true },
            format: { without: VendorDomains::DOMAIN_PATTERN }

  before_validation :prepare_domain
  before_save :prepare_domain

  private

  def prepare_domain
    self.domain = DomainCleaner.prepare(domain) if domain?
  end
end
