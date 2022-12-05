module Billing
  # зачисление вознаграждения партнеру
  # за определенную транзакцию вендора
  class Partner::IncomeReward
    include Virtus.model strict: true

    attribute :transaction, OpenbillTransaction
    attribute :vendor, Vendor # Магазин по которому прошла транзакция

    def call
      raise 'partner coupon not present' if partner_coupon.blank?

      make_transaction
    end

    private

    delegate :partner_coupon, to: :vendor
    delegate :partner, to: :partner_coupon

    def make_transaction
      OpenbillTransaction.create!(
        from_account_id: Billing::PARTNER_ACCOUNT_ID,
        to_account: partner.billing_account,
        key: [:partners, partner.id, transaction.id].join(':'),
        amount: amount,
        details: "Зачисление партнеру от магазина #{vendor.name}",
        date: Time.zone.today,
        meta: {
          transaction_id: transaction.id, partner_id: partner.id,
          vendor_id: vendor.id, transaction_amount: transaction.amount.to_i,
          coupon_code: partner_coupon.code
        }
      )
    end

    def amount
      transaction.amount / 100 * partner_coupon.reward_percent
    end
  end
end
