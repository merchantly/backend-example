module OrderUrls
  def operator_url
    Rails.application.routes.url_helpers.operator_order_url self, host: vendor.subdomained_url
  end

  def payment_url
    vendor.home_url + pay_vendor_order_path(external_id)
  end

  def client_order_url(params = {})
    vendor.home_url + vendor_order_path(external_id, params)
  end

  def public_url(params = {})
    client_order_url params
  end
end
