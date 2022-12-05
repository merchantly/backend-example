module VendorValidations
  extend ActiveSupport::Concern

  included do
    validates :http_cache_expires_in, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 }
    validates :name, presence: true
    validates :key,           presence: true, uniqueness: true
    validates :support_email, email: true, allow_blank: true
    validates :ms_sale_price_name, presence: true
    validates :ms_common_price_name, presence: true

    validates :tax_type, inclusion: { in: Settings::Taxes.list, allow_blank: true }

    validates :yandex_metrika_tracking_id, length: { maximum: 20 }
    validates :google_analytics_tracking_id, length: { maximum: 20 }
    validates :vk_export_period, allow_nil: true, numericality: { greater_than_or_equal_to: 1, only_integer: true }

    validates :custom_max_order_similar_products_count, allow_nil: true, numericality: { greater_than: 0, less_than_or_equal_to: Settings::Order.max_order_similar_products_count, only_integer: true }
    validates :custom_max_order_items_count, allow_nil: true, numericality: { greater_than: 0, less_than_or_equal_to: Settings::Order.max_order_items_count, only_integer: true }

    validates :max_allowance_cart_level_discount_percent,
              :max_allowance_item_level_discount_percent,
              :min_allowance_cart_level_discount_percent,
              :min_allowance_item_level_discount_percent,
              allow_blank: true,
              numericality: { greater_than: 0, less_than_or_equal_to: 100 }

    validates :tin, numericality: true, length: { is: 10 }, allow_blank: true

    validate :analytics_js_not_include_script_tag

    validate :validate_time_zone, if: :will_save_change_to_time_zone?

    validate :validate_zatca_fields if IntegrationModules.enable?(:zatca)
  end

  private

  def validate_time_zone
    return if ActiveSupport::TimeZone.all.map(&:name).include?(time_zone)

    erros.add :time_zone, I18n.t('errors.vendor.incorrect_time_zone')
  end

  def analytics_js_not_include_script_tag
    return unless will_save_change_to_analytics_js?

    errors.add(:analytics_js, I18n.t('errors.vendor_theme_form.analytics_js')) if analytics_js.present? && analytics_js.include?('<script')
  end

  def validate_zatca_fields
    errors.add :legal_additional_number, 'must be 4 digits' if legal_additional_number.present? && (legal_additional_number.to_s.length != 4)
    errors.add :legal_building_number, 'must contain 4 digits' if legal_building_number.present? && (legal_building_number.to_s.length < 4)
    errors.add :legal_post_code, 'must be 5 digits' if legal_post_code.present? && (legal_post_code.to_s.length != 5)

    if inn_present?
      inn_text_translations.each do |locale, inn|
        next if inn.blank?

        if (inn.length != 15) || !inn.start_with?('3') || !inn.end_with?('3')
          errors.add "inn_text_#{locale}", 'must contain 15 digits. The first and the last digits are “3”'
        end
      end
    end
  end
end
