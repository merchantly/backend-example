# TODO Перенести в OpenbillService
module Billing
  class IncomeFromCloudPayments
    GATEWAY = Billing::CLOUDPAYMENTS_GATEWAY_KEY

    def self.perform(t)
      assert_class! t, CloudPayments::Transaction

      raise "Unknown transaction reason '#{t.reason}'" unless t.reason == 'Approved'.freeze

      OpenbillTransaction.create!(
        from_account_id: CLOUDPAYMENTS_ACCOUNT_ID,
        to_account_id: t.account_id,
        key: [:payments, GATEWAY, t.id].join(':'),
        amount: t.amount.to_money(t.currency),
        details: t.description.presence || 'empty gateway description'.freeze,
        date: t.created_at,
        meta: {
          gateway: GATEWAY,
          cloud_payments_transaction: t,
          cloud_payments_transaction_id: t.id
        },
        invoice_id: t.invoice_id
      )
    end
  end
end
