class OrderPaymentYandexKassa < OrderPayment
  def template
    TEMPLATE_PAYMENT
  end

  def payments_fields
    YandexKassa::FormOptions.generate order.reload
  end

  def payment_url
    if vendor.yandex_kassa_test_mode?
      YandexKassa::API_DEMO_URL
    else
      YandexKassa::API_URL
    end
  end
end
