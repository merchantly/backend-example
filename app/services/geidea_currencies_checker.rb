class GeideaCurrenciesChecker
  include Sidekiq::Worker
  include AutoLogger

  WARNING_PERIOD = 3.days

  def perform(vendor_id)
    vendor = Vendor.find(vendor_id)

    payment = vendor.vendor_payments.alive.by_type(OrderPaymentGeideaPayment).first

    return if payment.blank?

    GeideaPaymentConfig::ErrorChecker.merchant_id payment.geidea_payment_merchant_id

    data = GeideaPaymentConfig::Requestor.perform(payment.geidea_payment_merchant_id)

    return if data[:currencies].blank?

    available_currencies = (vendor.available_currencies.to_a + [vendor.currency_iso_code]).uniq.compact

    if data[:currencies].exclude?(vendor.currency_iso_code) || (available_currencies.present? && (available_currencies != data[:currencies]))
      vendor.update! available_currencies: data[:currencies]

      exclude_currencies = available_currencies - data[:currencies]

      if exclude_currencies.include?(vendor.currency_iso_code)
        vendor.update! currency_iso_code: data[:currencies].first
      end

      vendor.add_operator_warning!(
        key: :currencies_checker,
        type: NotyFlashHelper::FLASH_ERROR,
        message: I18n.t('operator.check_currencies.flash', currency_symbol: exclude_currencies.join(', '), payment_name: payment.title),
        expired_at: (Time.zone.now + WARNING_PERIOD)
      )
    else
      vendor.remove_operator_warning(key: :currencies_checker)
    end
  rescue StandardError => e
    logger.error e
  end
end
