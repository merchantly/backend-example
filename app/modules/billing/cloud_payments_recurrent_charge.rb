# TODO Переименовать в Billing::CloudPayments::RecurrentCharge
#
module Billing
  class CloudPaymentsRecurrentCharge
    # Рекуррентный платеж с сохраненной карты для пополнения баланса аккаунта через CloudPayments
    # Вызывается из воркеров
    MAX_SUBTRACT_SUM = Settings.max_recharge_summ.to_money :rub

    include Virtus.model strict: true
    include Billing::ChargeLogging

    attribute :invoice, OpenbillInvoice
    attribute :payment_account, PaymentAccount

    def call
      log_charge 'start'
      validate!

      # Устанавливаем переменную объекта чтобы ею можно было воспользоваться из bugsnag
      @cloud_payments_transaction = charge!

      log_charge "CloudPayments Charged: #{@cloud_payments_transaction.to_json}", state: :success
      Billing.logger.info "Billing::CloudPaymentsRecurrentCharge: Снял с карты #{payment_account} #{invoice.amount} по счету #{invoice.id} для магазина #{invoice.vendor.try(:id)}"

      Billing::IncomeFromCloudPayments.perform @cloud_payments_transaction
      success_vendor_notify

      log_charge 'finish'
    rescue CloudPayments::Client::GatewayErrors::InsufficientFunds => e
      error! e, e.message, :retry
      vendor.notify e.message, subject: 'На карте не хватает средств для оплаты услуг'.freeze
      Billing.logger.warn "Billing::CloudPaymentsRecurrentCharge: Временная ошибка снятия с карты #{payment_account} #{e.message}"

      false
    rescue CloudPayments::Client::GatewayErrors::AntiFraud,
           CloudPayments::Client::GatewayErrors::BankNotSupportedBySwitch,
           CloudPayments::Client::GatewayErrors::ExpiredCard,
           CloudPayments::Client::GatewayErrors::Invalid,
           CloudPayments::Client::GatewayErrors::LostCard,
           CloudPayments::Client::GatewayErrors::StolenCard,
           CloudPayments::Client::GatewayErrors::ReferToCardIssuer => e

      error! e, e.message, :fatal
      vendor.notify e.message, subject: 'Не возможно выполнить оплату с помощью привязанной карты'.freeze
    rescue CloudPayments::Client::ReasonedGatewayError => e
      error! e, e.message, :fatal
      raise e
    rescue StandardError => e
      error! e, "Ошибка рекурентного платежа: #{e.message}", :fatal
      raise e
    end

    private

    delegate :vendor, to: :invoice

    def charge!
      CloudPayments.client.payments.tokens.charge(
        token: payment_account.token,
        amount: invoice.amount.to_f,
        currency: invoice.amount.currency.iso_code.upcase,
        account_id: invoice.destination_account_id,
        description: invoice.description,
        invoice_id: invoice.id
      )
    end

    def validate!
      raise AlreadyPaid if invoice.paid?
      raise LargeAmountError if invoice.amount > MAX_SUBTRACT_SUM
    end

    def success_vendor_notify
      vendor.notify "#{invoice.vendor}: Прошла оплата на сумму #{invoice.amount} по счету #{invoice.number} с карты #{payment_account.card}",
                    subject: 'Прошла оплата с карты'
    end

    def error!(err, message, state)
      Bugsnag.notify err, metaData: {
        cloud_payments_transaction: @cloud_payments_transaction.try(:as_json),
        charge_id: charge_log_entity.try(:id),
        payment_account: payment_account.as_json,
        vendor_id: vendor.id,
        invoice_id: invoice.id
      }

      SupportMailer.support_mail("#{err} #{message} у магазина #{vendor}").deliver_later!

      log_charge "#{err.class}: #{message}", state: state
    end

    class LargeAmountError < StandardError; end

    class AlreadyPaid < StandardError; end
  end
end
