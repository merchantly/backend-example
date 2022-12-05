class OrderPaymentPayPal < OrderPayment
  include VendorsHelper

  def template
    TEMPLATE_PAYMENT
  end

  def payments_fields
    PayPal::FormOptions.generate order.reload
  end

  def payment_url
    if Rails.env.production?
      PayPal::API_URL
    else
      PayPal::API_SANBOX_URL
    end
  end

  protected

  def cancel
    # TODO: w1 cancel payment!
  end
end
