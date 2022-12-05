class Certificate < ApplicationRecord
  mount_uploader :cert_file, CertificateFileUploader
  mount_uploader :key_file, CertificateKeyUploader

  validates :domain, presence: true, custom_domain: true, uniqueness: true, format: { without: VendorDomains::DOMAIN_PATTERN }

  validate :validate_key_file

  before_validation :set_cert_data, if: :will_save_change_to_cert_file?
  before_destroy :delete_vhost

  private

  def set_cert_data
    return if cert.blank?

    format_name = OpenSSL::X509::Name::COMPAT

    self.subject_name = cert.subject.to_s format_name
    self.issuer_name = cert.issuer.to_s format_name
    self.released_at = cert.not_before
    self.expired_at = cert.not_after
  end

  def delete_vhost
    CertificateService.new(certificate: self).delete_vhost
  end

  def cert
    @cert ||= OpenSSL::X509::Certificate.new cert_file.read
  rescue StandardError => e
    errors.add(:cert_file, :invalid_cert_file, error: e.message)

    nil
  end

  def validate_key_file
    OpenSSL::PKey::RSA.new key_file.read
  rescue StandardError => e
    errors.add(:key_file, :invalid_key_file, error: e.message)
  end
end
