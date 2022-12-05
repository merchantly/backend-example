class OrderPaymentRbkMoney < OrderPayment
  def template
    TEMPLATE_RBK_MONEY
  end

  def payment_url
    RbkMoney::API_URL
  end
end
