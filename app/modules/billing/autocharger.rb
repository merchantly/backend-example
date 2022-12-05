# Пытается списать оплату с карты
#
module Billing
  class Autocharger
    include Virtus.model strict: true

    attribute :invoice, OpenbillInvoice

    def call
      if invoice.is_autochargable?
        return true if internal_charge

        vendor.payment_accounts.where(gateway: Billing::CLOUDPAYMENTS_GATEWAY_KEY).active.each do |payment_account|
          return true if safe_charge payment_account
        end
      end

      VendorNotificationService.new(vendor).need_payment(invoice: invoice) unless vendor.archived?

      false
    end

    private

    delegate :vendor, to: :invoice

    def internal_charge
      return false if vendor.common_billing_account.amount < invoice.amount

      Billing::ChargeNextMonth.new(
        vendor: vendor,
        invoice: invoice,
        amount: invoice.amount,
        date: invoice.date.to_date,
        subkey: "internal-#{invoice.id}",
        meta: { autocharge: true }
      ).charge!

      true
    end

    def safe_charge(payment_account)
      Billing::CloudPaymentsRecurrentCharge.new(invoice: invoice, payment_account: payment_account).call
      true
    rescue StandardError => e # RecurrentCharge может генерировать ошибки, например сети и тп
      Billing.logger.error "Billing::Autocharger: Ошибка оплаты счета #{invoice.id} для магазина #{invoice.vendor_id}: #{e}"
      Bugsnag.notify e, metaData: { payment_account: payment_account.as_json, invoice: invoice.as_json, vendor_id: vendor.id }
      false
    end
  end
end
