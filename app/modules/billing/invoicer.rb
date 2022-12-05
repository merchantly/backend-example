# Централизованная подборка созданий счетов
# Чтобы было все в одном месте

module Billing
  class Invoicer
    include Virtus.model strict: true

    SERVICE_SMS    = 'sms'.freeze
    SERVICE_COMMON = 'common'.freeze # Собственно основная услуга, обслуживание
    SERVICE_OPEN   = 'open'.freeze   # Просто зачисление на счет, еще не понятно за что
    SERVICE_WORKS  = 'works'.freeze
    SERVICE_CERT   = 'cert'.freeze # За сертификат

    attribute :vendor, Vendor

    def self.create_next_month_invoice(vendor:, months_count: 1, amount: nil, tariff: nil, is_autochargable: false, details: nil)
      new(vendor: vendor)
        .create_next_month_invoice(months_count: months_count, amount: amount, tariff: tariff, is_autochargable: is_autochargable, details: details)
    end

    def self.create_negative_balance_invoice(vendor:)
      new(vendor: vendor)
        .create_negative_balance_invoice
    end

    def create_for_cert(domain:, amount:)
      invoice_date = Date.current
      create_invoice(
        number: invoice_number(invoice_date, "cert-#{domain}"),
        title: t(:cert, domain: domain),
        amount: amount,
        meta: {
          service: SERVICE_CERT,
          domain: domain
        }
      )
    end

    def create_for_sms_pack(sms_count:, amount:)
      invoice_date = Date.current
      create_invoice(
        number: invoice_number(invoice_date, "sms-#{sms_count}"),
        title: t(:sms_packet, sms_count: sms_count),
        amount: amount,
        meta: {
          service: SERVICE_SMS,
          sms_count: sms_count
        }
      )
    end

    def create_negative_balance_invoice
      invoice_date = common_billing_account.updated_at.to_date
      create_invoice(
        is_autochargable: true,
        number: invoice_number(invoice_date, 'debt'),
        title: t(:negative_balance, vendor: vendor.to_s),
        amount: -vendor.common_billing_account.amount,
        meta: {
          create_with: :create_negative_balance_invoice,
          service: SERVICE_COMMON,
          dept_pay: true
        }
      )
    end

    def create_next_month_invoice(months_count: 1, amount: nil, tariff: nil, is_autochargable: false, details: nil)
      tariff ||= vendor.tariff
      raise 'Не указан тариф' if tariff.blank?

      amount ||= tariff.month_price * months_count
      return if amount.zero?

      if paid_to.present?
        invoice_date = paid_to.next_day
        next_date = invoice_date.next_month months_count
        title = t :next_month_invoice_by_period, vendor: vendor, tariff: tariff, invoice_date: invoice_date, next_date: next_date, months_count: months_count
      else
        title = t :next_month_invoice, vendor: vendor, tariff: tariff, months_count: months_count
      end

      create_invoice(
        is_autochargable: is_autochargable,
        number: invoice_number(invoice_date || Date.current, [tariff.id, months_count].join('/')),
        title: title,
        amount: amount,
        details: details,
        meta: {
          service: SERVICE_COMMON,
          created_with: :create_next_month_invoice,
          vendor_id: vendor.id,
          current_paid_to: paid_to,
          next_paid_to: next_date,
          tariff_id: tariff.id,
          months_count: months_count,
          amount_month_price: (amount / months_count).to_f,
          tariff_month_price: tariff.month_price.to_f
        }
      )
    end

    def create_first_time_invoice(tariff:)
      create_invoice(
        amount: tariff.month_price,
        is_autochargable: false,
        number: invoice_number(Date.current, tariff.id),
        title: t(:first_time_invoice, vendor: vendor, tariff: tariff),
        meta: {
          service: SERVICE_COMMON,
          created_with: :create_first_time_invoice,
          current_paid_to: paid_to,
          vendor_id: vendor.id,
          tariff_id: tariff.id
        }
      )
    end

    def build_free_invoice(amount:, destination_account:, is_autochargable: false)
      OpenbillInvoice.new(
        destination_account: destination_account,
        is_autochargable: is_autochargable,
        date: Date.current,
        amount: amount,
        number: "#{Time.now.to_i}-#{vendor.id}",
        title: t(:free_invoice, vendor: vendor),
        meta: {
          service: SERVICE_OPEN,
          created_with: :build_free_invoice,
          vendor_id: vendor.id,
        }
      )
    end

    private

    delegate :common_billing_account, :tariff, :paid_to, to: :vendor

    def invoice_number(date, postfix)
      "#{vendor.id}-#{date}/#{postfix}"
    end

    def create_invoice(title:, amount:, number:, meta: {}, enable_notification: true, is_autochargable: false, details: nil)
      invoice = OpenbillInvoice
        .create_with(
          date: Date.current,
          title: title,
          amount: amount,
          meta: meta,
          is_autochargable: is_autochargable,
          enable_notification: enable_notification,
          details: details
        )
        .find_or_create_by(destination_account: common_billing_account, number: number)

      raise ActiveRecord::RecordInvalid.new(invoice) unless invoice.valid?

      Billing.logger.info "Billing::Invoicer: Create #{invoice.id} to #{invoice.amount} for #{invoice.vendor.id}" if invoice.created_at > 5.seconds.ago

      VendorNotificationService.new(vendor).need_payment(invoice: invoice)

      invoice
    end

    def t(key, options = {})
      I18n.t key, options.merge(scope: :billing)
    end
  end
end
