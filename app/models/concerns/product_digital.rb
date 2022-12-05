module ProductDigital
  extend ActiveSupport::Concern
  DOWNLOAD_EXPIRATION = Rails.env.production? ? 1.hour : 1.minute
  MAX_GENERATES = Rails.env.production? ? 3 : 50
  SIGNED_FOR = 'sharing'.freeze

  included do
    validates :file_url, url: true, if: :file_url
    validate :validate_digital
  end

  delegate :count, to: :active_digital_keys, prefix: true

  def download_sgid
    to_sgid expires_in: DOWNLOAD_EXPIRATION, for: SIGNED_FOR
  end

  def generate_download_url
    Rails.application.routes.url_helpers.download_vendor_product_url id: to_sgid.to_s, host: vendor.home_url
  end

  def has_digital_keys?
    digital_keys.present?
  end

  def active_digital_keys
    digital_keys.active
  end

  def validate_digital
    if is_digital? && (!has_digital_keys? && file_url.blank?)
        errors.add(:is_digital, 'Цифровой товар может иметь либо ссылку на файл, либо цифровые ключи')
      end
  end
end
