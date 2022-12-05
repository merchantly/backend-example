# https://money.yandex.ru/doc.xml?id=527069
#
require 'json'
module YandexKassa
  class FormOptions < BaseFormOptions
    OPTION_SHOP_ID = 'shopId'.freeze
    OPTION_SCID = 'scid'.freeze
    OPTION_CUSTOMER_NUMBER = 'customerNumber'.freeze
    OPTION_ORDER_NUMBER = 'orderNumber'.freeze
    OPTION_SUM = 'sum'.freeze
    OPTION_SUCCESS_URL = 'shopSuccessURL'.freeze
    OPTION_FAIL_URL = 'shopFailURL'.freeze

    private

    delegate :order_prices, to: :order

    def payment_currency
      :rub
    end

    def fill_fields
      add OPTION_SHOP_ID, vendor.yandex_kassa_shop_id
      add OPTION_SCID, vendor.yandex_kassa_scid
      add OPTION_CUSTOMER_NUMBER, vendor.id

      add OPTION_SUM, order.total_with_delivery_price.exchange_to(payment_currency).to_s
      add OPTION_ORDER_NUMBER, order.id

      add OPTION_SUCCESS_URL, success_vendor_payments_yandex_kassa_url(host: vendor.home_url)
      add OPTION_FAIL_URL, failure_vendor_payments_yandex_kassa_url(host: vendor.home_url)

      add PAYMENT_TYPE, order.payment_type.yandex_kassa_payment_method || DEFAULT_PAYMENT_METHOD

      if order.payment_type.online_kassa_provider_default?
        # https://github.com/yandex-money/yandex-money-joinup/blob/master/demo/54-fz.md#receipt
        raise YandexKassa::MaxCountItemsError if items.count >= MaxOrderItemsCountValidation::YANDEX_MAX_ITEMS_COUNT

        add 'ym_merchant_receipt', JSON.generate(merchant_receipt)
      end
    end

    # ФЗ-54
    # https://tech.yandex.ru/money/doc/payment-solution/payment-form/payment-form-receipt-docpage/
    #
    # 1 — общая СН;
    # 2 — упрощенная СН (доходы);
    # 3 — упрощенная СН (доходы минус расходы);
    # 4 — единый налог на вмененный доход;
    # 5 — единый сельскохозяйственный налог;
    # 6 — патентная СН.

    # В Киоске
    # tax_modes:
    #  - "Общая" # 0
    #  - "Упрощённая доход" # 1
    #  - "Упрощённая доход минус расход" # 2
    #  - "Единый налог на вменённый доход" # 3
    #  - "Единый сельскохозяйственный налог" # 4
    #  - "Патентная система налогообложения" # 5

    def taxSystem
      raise "Не установлена система налогоблажения у магазина #{vendor.id}" if vendor.tax_mode.blank?

      vendor.tax_mode + 1
    end

    def merchant_receipt
      {
        customer: {
          email: order.email,
          phone: order.phone
        },
        taxSystem: taxSystem,
        items: items.compact
      }
    end

    def price(money)
      { amount: money.exchange_to(payment_currency).to_f } # , currency: money.currency.to_s }
    end

    # Ставка НДС. Возможные значения — число от 1 до 6:
    # 1 — без НДС;
    # 2 — НДС по ставке 0%;
    # 3 — НДС чека по ставке 10%;
    # 4 — НДС чека по ставке 18%;
    # 5 — НДС чека по расчетной ставке 10/110;
    # 6 — НДС чека по расчетной ставке 18/118.
    #
    # В Киоске:
    #
    # tax_ru_1: "без НДС"
    # tax_ru_2: "НДС по ставке 0%"
    # tax_ru_3: "НДС чека по ставке 10%"
    # tax_ru_4: "НДС чека по ставке 18%"
    # tax_ru_5: "НДС чека по расчетной ставке 10/110"
    # tax_ru_6: "НДС чека по расчетной ставке 18/118"

    def tax_id(tax_type)
      raise 'Не указан код налога НДС' if tax_type.blank?

      tax_type.last.to_i
    end

    def items
      @items ||= order_prices.items.map do |item|
        {
          quantity: item.quantity,
          price: price(item.price),
          tax: tax_id(item.tax_type),
          text: text_truncate(item.title),
          paymentSubjectType: order.payment_type.online_kassa_payment_object,
          paymentMethodType: order.payment_type.online_kassa_payment_method
        }
      end + [delivery_line] + [package_line]
    end

    def delivery_line
      return if order.delivery_price.zero?

      {
        quantity: 1,
        price: price(order_prices.delivery.price),
        tax: tax_id(order_prices.delivery.tax_type),
        text: text_truncate(order_prices.delivery.title),
        paymentSubjectType: order.payment_type.online_kassa_payment_object,
        paymentMethodType: order.payment_type.online_kassa_payment_method
      }
    end

    def package_line
      return if order.package_price.zero?

      {
        quantity: 1,
        price: price(order_prices.package.price),
        tax: tax_id(order_prices.package.tax_type),
        text: text_truncate(order_prices.package.title)
      }
    end

    def text_truncate(text)
      # Ограничение яндекс-кассы
      # https://github.com/yandex-money/yandex-money-joinup/blob/master/demo/54-fz.md
      text.truncate 128
    end
  end
end
