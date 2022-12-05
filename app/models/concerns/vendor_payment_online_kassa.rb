module VendorPaymentOnlineKassa
  extend ActiveSupport::Concern

  PAYMENT_METHODS = %w[
    full_prepayment
    prepayment
    full_payment
    advance
    partial_payment
    credit
    credit_payment
  ].freeze

  DEFAULT_PAYMENT_METHOD = 'full_prepayment'.freeze

  PAYMENT_OBJECTS = %w[
    commodity
    payment
    excise
    job
    service
    gambling_bet
    gambling_prize
    lottery
    lottery_prize
    intellectual_activity
    agent_commission
    composite
    property_right
    nonoperating_gain
    insurance_premium
    sales_tax
    resort_fee
    another
  ].freeze

  DEFAULT_PAYMENT_OBJECT = 'commodity'.freeze

  included do
    enum online_kassa_provider: { disabled: 0, starrys: 1, default: 2, life_pay: 3, kassatka: 4, aqsi: 5 }, _prefix: true

    enumerize :online_kassa_payment_method, in: PAYMENT_METHODS, default: DEFAULT_PAYMENT_METHOD
    enumerize :online_kassa_payment_object, in: PAYMENT_OBJECTS, default: DEFAULT_PAYMENT_OBJECT

    validate :starrys_keys_presences, if: :online_kassa_provider_starrys?
    validate :life_pay_keys_presences, if: :online_kassa_provider_life_pay?
    validate :online_kassa_settings, if: :enable_online_kassa?

    validates :online_kassa_kassatka_address, presence: true, if: :online_kassa_provider_kassatka?
    validates :online_kassa_kassatka_port, presence: true, if: :online_kassa_provider_kassatka?

    validates :online_kassa_aqsi_client_key, presence: true, if: :online_kassa_provider_aqsi?
    validates :online_kassa_aqsi_shop_id, presence: true, if: :online_kassa_provider_aqsi?
    validates :online_kassa_aqsi_client_group_uuid, presence: true, if: :online_kassa_provider_aqsi?

    validates :online_kassa_payment_method, presence: true, if: :enable_online_kassa?
    validates :online_kassa_payment_object, presence: true, if: :enable_online_kassa?
  end

  def enable_online_kassa?
    !online_kassa_provider_disabled?
  end

  private

  def online_kassa_settings
    errors.add :online_kassa_provider, 'Необходимо установить в общих настройках систему налогооблажения и ставку НДС' unless vendor.tax_mode.present? && vendor.tax_type.present?
  end

  def life_pay_keys_presences
    return unless enable_online_kassa?

    errors.add :online_kassa_life_pay_login, 'Отсутсвует login для Онлайн кассы' if online_kassa_life_pay_login.blank?
    errors.add :online_kassa_life_pay_apikey, 'Отсутсвует apikey для Онлайн кассы' if online_kassa_life_pay_apikey.blank?
  end

  def starrys_keys_presences
    return unless enable_online_kassa?

    errors.add :online_kassa_key, 'Отсутсвует ключ для Онлайн кассы' if online_kassa_key.blank?
    errors.add :online_kassa_cert, 'Отсутсвует сертификат для Онлайн кассы' if online_kassa_cert.blank?
    errors.add :online_kassa_client_id, 'Отсутсвует client_id для Онлайн кассы' if online_kassa_client_id.blank?
    errors.add :online_kassa_password, 'Отсутсвует пароль для Онлайн кассы' if online_kassa_password.blank?
  end
end
