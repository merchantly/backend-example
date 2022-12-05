# http://www.walletone.com/ru/merchant/documentation/
#
module W1
  class FormOptions < BaseFormOptions
    DELIVERY_COMMENT_LIMIT = 255

    def generate
      @list = []

      fill_fields
      # В конце
      add_signature

      W1.logger.info vendor_id: vendor.id, order_id: order.id, message: 'Generate form', form: @list

      order_condition.mark_as_used_with_order! order if order_condition.present?

      @list
    end

    private

    attr_accessor :order_condition

    def fill_fields
      # WMI_CUSTOMER_FIRSTNAME
      # WMI_CUSTOMER_LASTNAME
      # WMI_CUSTOMER_EMAIL
      add_payment_no
      add_merchant_id
      add_payment_amount
      add_description
      add_currency
      add_return_urls
      add_payment_methods
      add_expired_date
      add_email if order.email.present?
      add_phone if order.phone.present? && order.email.blank?
      add_order_items if order.payment_type.enable_online_kassa? && order.payment_type.online_kassa_provider_default?

      if use_delivery?
        add_delivery_dates
        add_delivery
      end
    end

    def use_delivery?
      false # Отключили доставку через Redexpress
      # @force_delivery || has_order_condition?
    end

    def has_order_condition?
      return false unless order.order_delivery.is_a? OrderDeliveryRedexpress

      self.order_condition = order.possible_order_conditions.with_event(:on_create).first

      order_condition.present?
    end

    def add_payment_no
      add WMI_PAYMENT_NO, order.external_id
    end

    def add_merchant_id
      add 'WMI_MERCHANT_ID', vendor.w1_merchant_id
    end

    def add_payment_amount
      add 'WMI_PAYMENT_AMOUNT', format_number(order.total_with_delivery_price.to_f) # calculate_amount
    end

    def add_description
      add 'WMI_DESCRIPTION', payment_description
    end

    def add_currency
      add 'WMI_CURRENCY_ID', order.currency.iso_numeric
    end

    def add_return_urls
      add 'WMI_SUCCESS_URL',  success_vendor_payments_w1_url(host: vendor.home_url)
      add 'WMI_FAIL_URL',     failure_vendor_payments_w1_url(host: vendor.home_url)
    end

    def add_signature
      add WMI_SIGNATURE, signature
    end

    # https://www.walletone.com/ru/merchant/documentation/#step5
    def add_order_items
      add 'WMI_ORDER_ITEMS', order_items_to_json(build_order_items)
    end

    def build_order_items
      order_items = order.items.map do |item|
        {
          Title: item.title,
          Quantity: format_quantity(item.quantity),
          UnitPrice: format_number(item.price.to_f),
          SubTotal: format_number(item.total_price.to_f),
          TaxType: vendor.tax_type,
          Tax: format_number(item.tax.to_f)
        }
      end

      unless order.delivery_price.to_i.zero?
        order_items << {
          Title: 'Доставка',
          Quantity: '1.000',
          UnitPrice: format_number(order.delivery_price.to_f),
          SubTotal: format_number(order.delivery_price.to_f),
          TaxType: vendor.tax_type,
          Tax: format_number(TaxCalculator.new(price: order.delivery_price, vendor: vendor).perform.to_f)
        }
      end

      order_items
    end

    # W1 принимает числа с определенными кол-вами знаков после запятой
    # {UnitPrice: 10.00, SubTotal: 10.00, quantity: 1.000 }
    # На руби форматирование через '%.2f' возвращает строку и получается так
    # {UnitPrice: '10.00', SubTotal: '10.00', quantity: '1.000' }
    # W1 такое не переваривает - ему нужно именно числа
    def order_items_to_json(items)
      result = '['

      result << items.map do |item|
        json_item = '{'
        json_item << (item.as_json.map do |key, value|
          if (Float(value) rescue false)
            "#{ActiveSupport::JSON.encode(key.to_s)}:#{value}"
          else
            "#{ActiveSupport::JSON.encode(key.to_s)}:#{ActiveSupport::JSON.encode(value)}"
          end
        end * ',')
        json_item << '}'
      end.join(',')

      result << ']'
    end

    def format_number(number)
      '%.2f' % number
    end

    def format_quantity(quantity)
       '%.3f' % quantity
    end

    def add_email
      add 'WMI_CUSTOMER_EMAIL', order.email
    end

    def add_phone
      add 'WMI_CUSTOMER_PHONE', order.phone
    end

    def add_delivery_dates
      return if order.order_delivery.date_from.blank? || order.order_delivery.date_till.blank?

      add 'WMI_DELIVERY_DATEFROM',  I18n.l(order.order_delivery.date_from, format: :redexpress_delivery_date)
      add 'WMI_DELIVERY_DATETILL',  I18n.l(order.order_delivery.date_till, format: :redexpress_delivery_date)
    end

    def add_expired_date
      return unless order.will_cancel_at?

      add 'WMI_EXPIRED_DATE', order.will_cancel_at.utc.iso8601
    end

    # Доступные способы оплаты
    # http://www.walletone.com/ru/merchant/documentation/#step4
    def add_payment_methods
      if (list = order.payment_type.wmi_enabled_payment_methods).present?
        list.each do |value|
          add 'WMI_PTENABLED', value
        end
      end
      if (list = order.payment_type.wmi_disabled_payment_methods).present?
        list.each do |value|
          add 'WMI_PTDISABLED', value
        end
      end
    end

    # Документация по доставке
    # http://www.walletone.com/en/merchant/delivery/about/
    #
    def add_delivery
      # add 'WMI_DELIVERY_WAREHOUSEID',     '000000'

      add 'WMI_DELIVERY_REQUEST',         1
      add 'WMI_DELIVERY_COUNTRY',         order.country
      add 'WMI_DELIVERY_CITY',            order.city_to_delivery.squish
      add 'WMI_DELIVERY_ADDRESS',         order.address.squish
      add 'WMI_DELIVERY_CONTACTINFO',     order.phone
      add 'WMI_DELIVERY_COMMENTS',        delivery_comments
      add 'WMI_DELIVERY_ORDERID',         order.external_id

      # нужно этим магазинам прописать данную инф, тогда автомаически все заказы будут идти как подтвержденные
      add 'WMI_DELIVERY_SKIPINSTRUCTION', 1
    end

    def delivery_comments
      if Rails.env.production?
        order.comment.to_s[0..(DELIVERY_COMMENT_LIMIT - 1)]
      else
        'ТЕСТОВЫЙ ЗАКАЗ. НЕ ВЫПОЛНЯТЬ!'
      end
    end

    def add(key, value)
      # Таким образом избавляем от не совместимых в cp1251 символов
      value = value.encode('cp1251', invalid: :replace, undef: :replace).encode('utf-8') if value.is_a?(String)
      @list.push [key, value]
    end

    def signature
      W1.generate_signature_from_list(@list, vendor.vendor_walletone.merchant_sign_key)
    end

    def payment_description
      buffer = Rails.env.production? ? '' : 'Тестовый платеж! '
      buffer << order.description
      buffer.truncate(250)
      # encoded_desc = Base64.urlsafe_encode64(desc)
      # "BASE64:#{encoded_desc}"
    end

    # def calculate_amount
    # if order.payment_type.w1_payment_id == 'CreditCardRUB'
    # price = order.total_with_delivery_price.to_f
    # new_price = ((price*price)/(price*0.02 + price)).round(2)
    # new_price.to_s
    # else
    # order.total_with_delivery_price.to_s
    # end
    # end
  end
end
