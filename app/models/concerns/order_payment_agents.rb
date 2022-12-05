module OrderPaymentAgents
  MODULE_MAPPING = {
    cloud_payments: OrderPaymentCloudPayments,
    walletone: OrderPaymentW1,
    pay_pal: OrderPaymentPayPal,
    yandex_kassa: OrderPaymentYandexKassa,
    rbk_money: OrderPaymentRbkMoney,
    robokassa: OrderPaymentRobokassa,
    tinkoff: OrderPaymentTinkoff,
    sberbank: OrderPaymentSberbank,
    gsdk: OrderPaymentGsdk,
    geidea_payment: OrderPaymentGeideaPayment,
    direct: OrderPaymentDirect,
    invoice: OrderPaymentInvoice,
    arsenal_pay: OrderPaymentArsenalPay
  }.freeze

  def agents
    [
      OrderPaymentCloudPayments,
      OrderPaymentW1,
      OrderPaymentPayPal,
      OrderPaymentYandexKassa,
      OrderPaymentRbkMoney,
      OrderPaymentRobokassa,
      OrderPaymentTinkoff,
      OrderPaymentSberbank,
      OrderPaymentGsdk,
      OrderPaymentGeideaPayment,
      OrderPaymentDirect,
      OrderPaymentInvoice,
      OrderPaymentArsenalPay
    ]
  end

  def available_agents
    IntegrationModules.payments.map { |payment| MODULE_MAPPING[payment.to_sym] }.compact
  end
end
