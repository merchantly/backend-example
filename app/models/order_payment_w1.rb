class OrderPaymentW1 < OrderPayment
  include VendorsHelper

  def template
    if payment_type.wmi_enabled_payment_methods.include? 'RedCashRUB'
      TEMPLATE_CREATED
    else
      TEMPLATE_PAYMENT
    end
  end

  def payments_fields
    W1::FormOptions.generate order.reload
  end

  def payment_url
    if order.vendor.id == 68 # TODO Сахарок
      W1::OLD_CHECKOUT_URL
    else
      W1::NEW_CHECKOUT_URL
    end
  end

  protected

  def cancel
    # TODO: w1 cancel payment!
  end
end
