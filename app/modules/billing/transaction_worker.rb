# Воркер вызывается в тот момент, когда приходит какая-либо транзакция
# TODO Переименовать в TransactionCallback?
module Billing
  class TransactionWorker
    include Sidekiq::Worker
    include MoneyRails::ActionViewExtension
    include MoneyHelper
    include SupportEmail

    def perform(transaction_id)
      @transaction = OpenbillTransaction.find(transaction_id)

      if transaction.vendor_incoming?
        # Уведомляем менеджеров магазина о пополении баланса
        VendorNotificationService.new(transaction.vendor).balance_refill(transaction)

        case_common_transaction

      elsif transaction.vendor_outcoming?
        reward_partner! if reward_partner?

        # уведомляем вендора о всех списаниях кроме незалоченых SMS
        # отключили для экономии на SMS
        # VendorNotificationService.new(transaction.vendor).balance_subtract(transaction) if transaction.to_account.id == Billing::SYSTEM_ACCOUNTS[:subscriptions]
      elsif transaction.partner_incoming?
        VendorNotificationService.new(transaction.partner).partner_incoming(transaction)

      else
        support_email 'Непонятная транзакция'
      end
    end

    def recharge_sms_service(t, sms_income)
      @transaction = t
      charge_sms_service! sms_income
    end

    private

    attr_reader :transaction

    delegate :vendor, :invoice, to: :transaction

    # Деньги пришли на основной счет
    def case_common_transaction
      OrangeDataWorker.perform_async transaction.id if (transaction.from_account_id == Billing::CLOUDPAYMENTS_ACCOUNT_ID) && Rails.env.production?

      # Например оплата такая: https://billing.kiiiosk.store/transactions/d8dc89d3-0714-4b7d-bf3d-59b2d7de83cd
      # В этом случае нужно использовать прошлый тариф
      return income_transaction_without_invoice if invoice.blank?

      case invoice.meta.service.presence
      when Billing::Invoicer::SERVICE_OPEN
        support_email "Зачислены средства по открытому счету (#{invoice.service}) #{invoice.meta}."

      when Billing::Invoicer::SERVICE_SMS
        charge_sms_service!

      when Billing::Invoicer::SERVICE_COMMON
        income_common_transaction

      when nil
        # Старые счета, без указания сервиса
        if vendor.tariff.present? && invoice.amount == transaction.amount && invoice.amount == vendor.tariff.month_price
          charge_common_service!
        else
          # тут не плохо было бы сразу списывать за абонплату и други услуги, если уже подоспело,
          # хотя, наверное, оно автотом спишется при recharge
          support_email 'Оплачен счет без указания услуги'
        end
      else
        # Например бывает fz54 по старым счетам
        # TODO invoice.service.paid! invoice.amount
        support_email "Оплачет счет за дополнительные услуги (#{invoice.service}) #{invoice.meta}. Пора зпускать эти услуги в работу ;)"
      end
    end

    def income_common_transaction
      return income_transaction_with_invoice_but_without_tariff if invoice.tariff.blank?

      if invoice.tariff.month_price.positive?
        raise 'Не могу прологнировать без счета' if invoice.blank?

        months_count = invoice.meta.months_count.presence || 1
        unless transaction.amount == (invoice.tariff.month_price * months_count.to_i)
          raise "Сумма транзакции (#{transaction.amount} #{transaction.amount_currency}) по счету #{invoice.id} не равна сумме тарифа (#{invoice.tariff.month_price} #{invoice.tariff.month_price_currency}) * #{months_count} мес."
        end

        charge_common_service!
      else
        support_email 'Оплачен счет, но у счета тариф с без абонплаты'
      end
    end

    def income_transaction_without_invoice
      if vendor.tariff.present?
        if transaction.amount == vendor.tariff.month_price
          charge_common_service!
        else
          support_email 'Пришла оплата без счета. Сумма оплаты не соответсвует тарифу'
        end
      else
        support_email 'Пришла оплата без счета. У магазина нет тарифа, не знаем что делать'
      end
    end

    def income_transaction_with_invoice_but_without_tariff
      if vendor.tariff.present?
        if invoice.amount == vendor.tariff.month_price
          charge_common_service!
        else
          support_email 'Оплачен не понятный счет. Сумма по счету не совпадает с текущим тарифом. Тариф в счете не установлен'
        end
      else
        support_email 'Оплачет не понятный счет. Тарифа ни в счете, ни у магазина нет'
      end
    end

    def charge_sms_service!(sms_income = nil)
      OpenbillTransaction.transaction do
        sms_income ||= vendor.vendor_sms_incomes.create! count: invoice.meta.sms_count, comment: "Зачисление SMS по счету #{invoice.number}"

        amount = invoice.amount
        details = "Снимаю сумму #{amount} со внутреннего счета магазина #{vendor.id} за SMS #{invoice.meta.sms_count}, по счету #{invoice.try(:number) || 'без счета'}"
        key = ['sms-outcome-by-invoice', invoice.id].join(':')
        meta = {
          invoice_id: invoice.id,
          sms_count: invoice.meta.sms_count,
          vendor_sms_income_id: sms_income.id
        }
        Billing.logger.info "Billing::ChargeSMS: #{details}, key=#{key}, meta=#{meta}"

        OpenbillTransaction.create!(
          from_account: vendor.common_billing_account,
          to_account_id: Billing::SYSTEM_ACCOUNTS[:sms],
          key: key,
          amount: amount,
          details: details,
          date: Time.zone.today,
          meta: meta
        )
      end
    end

    def charge_common_service!
      raise 'Счета различаются' unless transaction.to_account == vendor.common_billing_account
      raise 'Сумма транзакции не равна сумме счета' if invoice.present? && transaction.amount != invoice.amount

      months_count = 1
      months_count = invoice.meta.months_count.to_i if invoice.present? && invoice.meta.months_count.present?

      OpenbillTransaction.transaction do
        Billing::ChargeNextMonth.new(
          vendor: vendor,
          invoice: invoice,
          amount: transaction.amount,
          date: transaction.date,
          subkey: transaction.id.to_s,
          meta: transaction.meta.to_h,
          months_count: months_count
        ).charge!

        VendorCommand::RestoreCommand.new(vendor: vendor).call if vendor.archived?
        VendorCommand::Publish.new(vendor: vendor).call rescue VendorCommand::Publish::NotPaidError

        vendor.invoices.alive.not_paid.with_tariff.update_all archived_at: Time.zone.now
      end
    end

    def reward_partner!
      Billing::Partner::IncomeReward.new(transaction: transaction, vendor: vendor).call
    end

    def reward_partner?
      vendor.partner.present? && vendor.partner_coupon.present? && (vendor.partner_coupon.perpetual? || vendor.partner_coupon_active_to >= Date.current)
    end
  end
end
