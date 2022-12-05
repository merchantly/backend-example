module Billing
  # Списывает с основого счета оплату за обслуживание
  # и устанавливает дату оплаты (paid_to) и работы (working_to)
  class ChargeNextMonth
    include Virtus.model
    include MoneyRails::ActionViewExtension

    WORKING_TO_PERIOD = 2.weeks

    attribute :vendor, Vendor, strict: true
    attribute :amount, Money, strict: true
    attribute :date, Date, strict: true
    attribute :subkey, String, strict: true
    attribute :meta, Hash, strict: true
    attribute :next_paid_to, Date
    attribute :months_count, Integer, strict: true, default: 1

    attribute :invoice, OpenbillInvoice

    delegate :tariff, to: :invoice, allow_nil: true

    def charge!
      self.next_paid_to ||= (vendor.paid_to || Date.current).next_month(months_count)

      vendor.transaction do
        previous = update_vendor_working_dates
        charge_next_month previous
      end
    rescue StandardError => e
      binding.debug_error
      Bugsnag.notify e, metaData: { invoice: invoice, vendor: vendor, meta: meta, date: date, amount: amount, subkey: subkey }
      Billing.logger.error "Billing::ChargeNextMonth: (total) #{e}"
    end

    private

    def next_working_to
      new_working_to = next_paid_to + WORKING_TO_PERIOD

      if vendor.working_to.nil? || vendor.working_to < new_working_to
        new_working_to
      else
        vendor.working_to
      end
    end

    def update_vendor_working_dates
      vendor.paid_to = next_paid_to
      vendor.working_to = next_working_to
      vendor.tariff = tariff if tariff.present?

      changes = vendor.changes.dup

      # TODO Записать в vendor_activity
      vendor.save!

      changes
    end

    # Списываем абонплату за следующий месяц
    def charge_next_month(changes = {})
      details = I18n.t(
        'services.tariff_payment.fee.per_month.description',
        date: I18n.l(date, format: '%B %Y'),
        amount: humanized_money_with_symbol(amount)
      )

      meta = meta.to_h.merge(
        workflow: :charge_next_month,
        changes: changes,
        set_tariff_id: tariff.try(:id),
        income_invoice_id: invoice.try(:id)
      )

      key = ['subscription-outcome', subkey].join(':')

      Billing.logger.info "Billing::ChargeNextMonth: Снимаю сумму #{amount} со внутреннего счета магазина #{vendor.id} за обслуживание #{details}, по счету #{invoice.try(:id) || 'без счета'}, key=#{key}, meta=#{meta}"

      OpenbillTransaction.create!(
        from_account: vendor.common_billing_account,
        to_account_id: Billing::SUBSCRIPTIONS_ACCOUNT_ID,
        key: key,
        amount: amount,
        details: details,
        date: Time.zone.today,
        invoice: invoice,
        meta: meta
      )
    rescue StandardError => e
      Bugsnag.notify e, metaData: { changes: changes, invoice_id: invoice.try(:id), tariff_id: tariff.try(:id), details: details, meta: meta, key: key }
      Billing.logger.error "Billing::ChargeNextMonth: (transaction) #{e}"
      raise e
    end
  end
end
