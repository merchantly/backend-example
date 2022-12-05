module Vendor::AccountBilling
  extend ActiveSupport::Concern

  COMMON_OPENBILL_PREFIX = 'client-'.freeze
  VENDOR_CLIENTS_PREFIX = 'vendor-clients-'.freeze
  VENDOR_EXPENSE_PREFIX = 'vendor-expense-'.freeze
  VENDOR_RECEIPT_PREFIX = 'vendor-receipt-'.freeze
  VENDOR_CORRECT_PREFIX = 'vendor-correct-'.freeze

  included do
    has_one :common_billing_account, -> { where(category_id: Billing::CLIENTS_CATEGORY_ID) }, class_name: 'OpenbillAccount', as: :reference

    has_one :client_account, -> { where(category_id: Billing::ECR_VENDOR_CLIENTS_CATEGORY_ID) }, class_name: 'OpenbillAccount', as: :reference
    has_one :expense_account, -> { where(category_id: Billing::ECR_VENDOR_EXPENSE_CATEGORY_ID) }, class_name: 'OpenbillAccount', as: :reference
    has_one :receipt_account, -> { where(category_id: Billing::ECR_VENDOR_RECEIPT_CATEGORY_ID) }, class_name: 'OpenbillAccount', as: :reference
    has_one :correct_account, -> { where(category_id: Billing::ECR_VENDOR_CORRECT_CATEGORY_ID) }, class_name: 'OpenbillAccount', as: :reference

    has_many :openbill_accounts, as: :reference
    has_many :invoices, through: :openbill_accounts

    scope :negative_balance, -> { joins(:common_billing_account).merge(OpenbillAccount.negative_balance) }

    after_create :create_billing_accounts
    after_create :create_ecr_accounts
  end

  delegate :amount, to: :common_billing_account

  def publish!
    update_attribute :is_published, true
  end

  def unpublish!
    update_attribute :is_published, false
  end

  def outgoing_openbill_transactions
    OpenbillTransaction.where(from_account_id: openbill_accounts)
  end

  def incoming_openbill_transactions
    OpenbillTransaction.where(to_account_id: openbill_accounts)
  end

  def needs_recurrent_charge?
    have_payment_account? && amount.to_i.negative?
  end

  # есть ли сохраненные данные для рекурентного платежа?
  def have_payment_account?
    payment_accounts.active.any?
  end

  # card <CardEntity>
  def save_payment_card(card, gateway)
    payment_account = payment_accounts.by_token(card.token).take

    if payment_account.present?
      # Пользователь вбивает карту с галочкой  'Сохранить как основной способ оплаты'.
      # Система видя что помечена галочка пытается сохранить карту.
      # Если карта уже существует и она отвязана(archive), то система не должна восстанавливать ее.
      Billing.logger.info "Payment card is archived #{payment_account.id}" if payment_account.archived?
    else
      payment_accounts.create! card.to_hash.merge(gateway: gateway)
    end
  rescue StandardError => e
    Bugsnag.notify e, metaData: { card: card }
  end

  private

  # поле key - legacy
  def create_billing_accounts
    create_common_billing_account(
      category_id: Billing::CLIENTS_CATEGORY_ID,
      details: [name.presence, subdomain].join(' '),
      key: COMMON_OPENBILL_PREFIX + id.to_s,
      amount_currency: Money.default_currency.iso_code,
      meta: { url: home_url, shop_id: id, subdomain: subdomain, phone: phone }
    )
  end

  def create_ecr_accounts
    if client_account.blank?
      create_client_account(
        category_id: Billing::ECR_VENDOR_CLIENTS_CATEGORY_ID,
        details: "Ecr vendor clients #{id}",
        key: VENDOR_CLIENTS_PREFIX + id.to_s,
        amount_currency: Money.default_currency.iso_code,
        meta: { vendor_id: id }
      )
    end

    if expense_account.blank?
      create_expense_account(
        category_id: Billing::ECR_VENDOR_EXPENSE_CATEGORY_ID,
        details: "Ecr vendor expense #{id}",
        key: VENDOR_EXPENSE_PREFIX + id.to_s,
        amount_currency: Money.default_currency.iso_code,
        meta: { vendor_id: id }
      )
    end

    if receipt_account.blank?
      create_receipt_account(
        category_id: Billing::ECR_VENDOR_RECEIPT_CATEGORY_ID,
        details: "Ecr vendor receipt #{id}",
        key: VENDOR_RECEIPT_PREFIX + id.to_s,
        amount_currency: Money.default_currency.iso_code,
        meta: { vendor_id: id }
      )
    end

    if correct_account.blank?
      create_correct_account(
        category_id: Billing::ECR_VENDOR_CORRECT_CATEGORY_ID,
        details: "Ecr vendor correct #{id}",
        key: VENDOR_CORRECT_PREFIX + id.to_s,
        amount_currency: Money.default_currency.iso_code,
        meta: { vendor_id: id }
      )
    end
  end
end
