module LifePay
  class Requestor
    include Virtus.model strict: true

    attribute :order, Order

    def perform
      LifePay.logger.info "Выполняю запрос по заказу #{order.id}.."
      client = ::LifePay::Client.new(
        login: payment_type.online_kassa_life_pay_login,
        apikey: payment_type.online_kassa_life_pay_apikey,
        test: payment_type.is_online_kassa_test_mode?
      )
      res = client.create_receipt data
      LifePay.logger.info "Заказ #{order.id}. Результат: #{res}"
    rescue StandardError => e
      Bugsnag.notify e, metaData: { order_id: order.id }
      LifePay.logger.error "Заказ #{order.id}. Ошибка: #{e}"
      raise e
    end

    private

    delegate :vendor, :payment_type, :order_prices, to: :order

    def data
      d = {
        type: :payment,
        mode: :email,
        purchase: {
          products: products.compact
        },
        card_amount: order.total_with_delivery_price.to_f
      }

      d[:customer_email] = order.email if order.email.present?
      d[:customer_phone] = order.phone if order.phone.present?
      d
    end

    TAX_IDS = {
      tax_ru_1: :none,
      tax_ru_2: :vat0,
      tax_ru_3: :vat10,
      tax_ru_4: :vat18,
      tax_ru_5: :unknown_10_110,
      tax_ru_6: :unknown_18_118,
      tax_ru_7: :vat20,
      tax_ru_8: :unknown_20_120
    }.freeze

    def tax_id(tax_type)
      raise 'Не указан код налога НДС' if tax_type.blank?

      TAX_IDS[tax_type.to_sym] || raise("Не известный код налога НДС #{tax_type}")
    end

    def products
      order_prices.items.map do |item|
        {
          name: item.title,
          price: item.price.to_f,
          quantity: item.quantity,
          unit: :piece, #  kg - килограммы, g - граммы, l - литры, ml - миллилитры, m2 - квадратные метры
          tax: tax_id(item.tax_type),
          type: 1, # Полная предварительная оплата до момента передачи предмета расчета;
          item_type: 1 # Товар
        }
      end + [delivery_line, package_line]
    end

    def delivery_line
      return if order.delivery_price.zero? || order.delivery_price.nil?

      {
        name: order_prices.delivery.title,
        quantity: 1,
        unit: :piece,
        price: order_prices.delivery.price.to_f,
        tax: tax_id(order_prices.delivery.tax_type),
        type: 1, # Полная предварительная оплата до момента передачи предмета расчета;
        item_type: 4 # Услуга
      }
    end

    def package_line
      return if order.package_price.zero?

      {
        name: order_prices.package.title,
        quantity: 1,
        unit: :piece,
        price: order_prices.package.price.to_f,
        tax: tax_id(order_prices.package.tax_type),
        type: 1, # Полная предварительная оплата до момента передачи предмета расчета;
        item_type: 1 # Товар
      }
    end
  end
end
