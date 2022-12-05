# https://developer.paypal.com/docs/classic/paypal-payments-standard/integration-guide/cart_upload/
#
module PayPal
  class FormOptions < BaseFormOptions
    private

    def fill_fields
      add_email
      add_cmd
      add_currency
      # add_products
      add_order
      add_upload
      add_callback_url
      add_notify_url
      add_charset

      add_custom

      # Пока что передаем всю сумму полностью без разделения на составляющие
      # add_delivery_price
    end

    def add_custom
      add 'custom', { order_id: order.id, order_amount: order.total_with_delivery_price.to_s }.to_json
    end

    def add_charset
      add 'charset', 'utf-8'
    end

    def add_email
      add 'business', vendor.pay_pal_email
    end

    def add_cmd
      add 'cmd', '_cart'
    end

    def add_currency
      add 'currency_code', order.currency_iso_code
    end

    # пока что не используется, вместо продуктов добавляем add_order
    def add_products
      order.items.each_with_index do |item, index|
        add "item_name_#{index + 1}", item.title
        add "quantity_#{index + 1}", item.count.to_s
        add "amount_#{index + 1}", item.price.to_s
      end
    end

    def add_order
      add 'item_name_1', "Заказ №#{order.id}"
      add 'quantity_1', '1'
      add 'amount_1', order.total_with_delivery_price.to_s
    end

    def add_upload
      add 'upload', '1'
    end

    def add_delivery_price
      add 'shipping_1', order.delivery_price
    end

    def add_callback_url
      add 'return', success_vendor_payments_pay_pal_url(host: vendor.home_url)
      add 'cancel_return', failure_vendor_payments_pay_pal_url(host: vendor.home_url)
    end

    def add_notify_url
      # add 'notify_url', "http://apitest.localtunnel.me/v1/callbacks/pay_pal/payments/#{vendor.id}/notify"
      add 'notify_url', vendor.pay_pal_payment_callback_url
    end
  end
end
