module OrderWalletone
  extend ActiveSupport::Concern
  PREFIX = 'k'.freeze
  AVAILABLE_PREFIXES = %w[k kiiiosk kiosk].freeze

  included do
    def self.find_by_external_id(external_id)
      vendor_id, order_id = parse_external_id external_id
      where(vendor_id: vendor_id, id: order_id).take!
    end

    def self.by_external_id(external_id)
      vendor_id, order_id = parse_external_id external_id
      where(vendor_id: vendor_id, id: order_id)
    rescue StandardError
      none
    end
  end

  module ClassMethods
    # kiosk:7-648-pro
    def parse_external_id(number)
      prefix, vendor_id, order_id = number.to_s.split(/:|-/)

      raise WrongNumberFormat, "Неверный внешний номер заказа #{number}" if prefix.present? && AVAILABLE_PREFIXES.exclude?(prefix)
      raise WrongNumberFormat, "Неверный внешний номер заказа #{number} (нет заказа: '#{number}')" if order_id.blank?
      raise WrongNumberFormat, "Неверный внешний номер заказа #{number} (нет вендора: '#{number}')" if vendor_id.blank?

      [vendor_id, order_id]
    end
  end

  # production:  kiosk:7-648
  # development: kiosk:7-648-dev
  #
  def external_id
    suffix = Rails.env.slice(0, 3) unless Rails.env.production?

    [PREFIX, vendor.external_id, id, suffix].compact.join '-'
  end

  WrongNumberFormat = Class.new StandardError
end
