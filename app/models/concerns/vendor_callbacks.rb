module VendorCallbacks
  extend ActiveSupport::Concern

  included do
    before_validation :generate_key
    before_save :set_available_locales
    before_create :generate_preview_code
    after_create :create_theme!
    after_save :change_default_product_vat_group, if: :legal_country_code_previously_changed?

    before_create do
      self.first_billing_payment_amount = zero_money if first_billing_payment_amount_currency.nil?
      self.minimal_price = zero_money if minimal_price_currency.nil?
    end
  end

  private

  def generate_preview_code
    self.preview_code ||= SecureRandom.hex
  end

  def generate_key
    self.key = SecureRandom.hex if key.blank?
  end

  def set_available_locales
    self.default_locale ||= I18n.default_locale
    self.available_locales = Settings.default_enabled_locales if available_locales.blank?

    if available_locales_changed?
      self.available_locales = available_locales.uniq.compact.select do |l|
        I18n.available_locales.include? l.to_sym
      end
    end
  end

  def change_default_product_vat_group
    return if default_product_vat_group.blank?

    default_product_vat_group.update! vat: DefaultProductVatGroup.find_by_country_code_or_default(legal_country_code).vat
  end
end
