module Partner::AccountBilling
  extend ActiveSupport::Concern

  PARTNER_OPENBILL_PREFIX = 'partner-'.freeze

  included do
    has_one :billing_account, -> { where(category_id: Billing::PARTNERS_CATEGORY_ID) }, class_name: 'OpenbillAccount', as: :reference
    after_create :create_openbill_account
  end

  def transactions
    OpenbillTransaction.where(to_account_id: billing_account.id)
  end

  def incoming_transactions
    transactions.where(from_account_id: Billing::PARTNER_ACCOUNT_ID)
  end

  private

  def create_openbill_account
    create_billing_account(
      category_id: Billing::PARTNERS_CATEGORY_ID,
      key: billing_account_ident,
      details: billing_account_details,
      amount_currency: Money.default_currency.iso_code,
      meta: {}
    )
    # legacy
    update_column :billing_account_uuid, billing_account.id
  end

  def billing_account_ident
    PARTNER_OPENBILL_PREFIX + id.to_s
  end

  def billing_account_details
    [name.presence].join ' '
  end
end
