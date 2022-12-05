module VendorPaymentInquirer
  def e_invoice?
    (gsdk? && (gsdk_payment_type == Gsdk::E_INVOICE)) || (geidea_payment? && (geidea_payment_type == GeideaPayment::E_INVOICE))
  end

  def cash?
    payment_agent_type == 'OrderPaymentDirect'
  end

  def gsdk?
    payment_agent_type == 'OrderPaymentGsdk'
  end

  def cloudpayments?
    payment_agent_type == 'OrderPaymentCloudPayments'
  end

  def tinkoff?
    payment_agent_type == 'OrderPaymentTinkoff'
  end

  def robokassa?
    payment_agent_type == 'OrderPaymentRobokassa'
  end

  def sberbank?
    payment_agent_type == 'OrderPaymentSberbank'
  end

  def yandex_kassa?
    payment_agent_type == 'OrderPaymentYandexKassa'
  end

  def arsenal_pay?
    payment_agent_type == 'OrderPaymentArsenalPay'
  end

  def geidea_payment?
    payment_agent_type == 'OrderPaymentGeideaPayment'
  end
end
