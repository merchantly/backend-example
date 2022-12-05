module Billing
  class IncomeFromGsdk
    def self.perform(invoice)
      OpenbillTransaction.create!(
        from_account_id: Billing::GSDK_ACCOUNT_ID,
        to_account_id: invoice.destination_account_id,
        key: [:payments, Billing::GSDK_GATEWAY_KEY, SecureRandom.uuid].join(':'),
        amount: invoice.amount,
        details: invoice.title,
        date: DateTime.current,
        invoice_id: invoice.id,
        meta: {
          gateway: GSDK_GATEWAY_KEY
        }
      )
    end
  end
end
