module VendorPaymentValidation
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true, length: { maximum: 200 }

    # Уникальность отлкючили, потому что возникают проблемы с названиями уже удаленных оплат.
    # Нужно проверять на уникальность, только в мире живых. Не придумал как это сделать быстро.
    #
    # validates :title, uniqueness: { scope: :vendor_id }, if: :alive?
    validates :payment_agent_type, presence: true, inclusion: { in: OrderPayment.available_agents.map(&:name) }
    validates :canceling_timeout_minutes, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: (2.weeks / 60)
    }

    validates :cloud_payments_public_id, presence: true, if: :cloudpayments?
    validates :cloud_payments_api_key, presence: true, if: :cloudpayments?

    validates :robokassa_login, presence: true, if: :robokassa?
    validates :robokassa_first_password, presence: true, if: :robokassa?
    validates :robokassa_second_password, presence: true, if: :robokassa?

    validates :tinkoff_terminal_key, presence: true, if: :tinkoff?
    validates :tinkoff_password, presence: true, if: :tinkoff?

    validates :sberbank_login, presence: true, if: :sberbank?
    validates :sberbank_api_token, presence: true, if: :sberbank?
    validates :sberbank_private_key, presence: true, if: :sberbank?

    validates :gsdk_tid, presence: true, if: :gsdk?
    validates :gsdk_mid, presence: true, if: :gsdk?
    validates :gsdk_secret_code, presence: true, if: :gsdk?
    validates :gsdk_payment_type, presence: true, inclusion: { in: Gsdk::PAYMENT_TYPES }, if: :gsdk?

    validates :geidea_payment_merchant_id, presence: true, if: :geidea_payment?
    validates :geidea_payment_api_password, presence: true, if: :geidea_payment?
    validates :geidea_payment_type, presence: true, if: :geidea_payment?
    validate :validate_geidea_payment_config, if: :geidea_payment?

    validates :arsenal_pay_widget, presence: true, if: :arsenal_pay?

    def validate_geidea_payment_config
      GeideaPaymentConfig::ErrorChecker.merchant_id(geidea_payment_merchant_id) if geidea_payment_merchant_id.present?
    end
  end
end
