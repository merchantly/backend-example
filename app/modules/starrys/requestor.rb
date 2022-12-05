module Starrys
  class Requestor
    # Количество товара передаётся в тысячных долях.  Если вы продаёт одну единицу - нужно откравлять "Qty" : 1000
    MULTIPLICATOR = 1000

    include Virtus.model strict: true

    attribute :order, Order

    # Таблица N1
    # 0 Приход
    # 1 Расход
    # 2 Возврат прихода
    # 3 Возврат расхода
    #
    attribute :document_type, Integer, default: 0

    def perform
      Starrys.logger.info "Выполняю запрос по заказу #{order.id}.."
      client = ::Starrys::Client.new(
        client_cert: payment_type.online_kassa_cert,
        client_key: payment_type.online_kassa_key,
        test: payment_type.is_online_kassa_test_mode?
      )
      res = client.complex data
      Starrys.logger.info "Заказ #{order.id}. Результат: #{res}"
    rescue StandardError => e
      Starrys.logger.error "Заказ #{order.id}. Ошибка: #{e}"
      raise e
    end

    private

    delegate :vendor, :payment_type, :order_prices, to: :order

    def request_id
      "#{order.public_id}-#{Time.now.to_i}"
    end

    def phone_or_email
      order.phone.presence || order.email
    end

    def data
      attr = {
        Device: 'auto',
        DocumentType: document_type,
        ClientId: payment_type.online_kassa_client_id.to_s,
        Password: payment_type.online_kassa_password.to_i,
        RequestId: request_id,
        Lines: lines.compact,
        NonCash: [order_prices.total_price.cents, 0, 0],
        PhoneOrEmail: phone_or_email,
        Place: vendor.active_domain_unicode,
        FullResponse: false
      }

      # Указывается если в налоговой зарегистрировано более 1-й системы
      # налогооблажения
      # "TaxMode": tax_mode
      #
      # В киоске порядок и нумерация tax_mode совпадает со starrys
      # потому отдаем как есть
      # Таблица N3. Тип системы налогообложения
      #
      # 0   Общая
      # 1   Упрощённая доход
      # 2   Упрощённая доход минус расход
      # 3   Единый налог на вменённый доход
      # 4   Единый сельскохозяйственный налог
      # 5   Патентная система налогообложения

      attr['TaxMode'] = vendor.tax_mode if vendor.tax_mode.present?
      attr
    end

    # tax_id Налоги
    #
    # 1 - НДС 18%
    # 2 - НДС 10%
    # 3 - НДС 0%
    # 4 - Без налога
    # 5 - Ставка 18/118
    # 6 - Ставка 10/110

    # В Киоске:
    #
    # tax_ru_1: "без НДС"
    # tax_ru_2: "НДС по ставке 0%"
    # tax_ru_3: "НДС чека по ставке 10%"
    # tax_ru_4: "НДС чека по ставке 18%"
    # tax_ru_5: "НДС чека по расчетной ставке 10/110"
    # tax_ru_6: "НДС чека по расчетной ставке 18/118"

    TAX_IDS = {
      tax_ru_1: 4,
      tax_ru_2: 3,
      tax_ru_3: 2,
      tax_ru_4: 1,
      tax_ru_5: 6,
      tax_ru_6: 5
    }.freeze

    def tax_id(tax_type)
      raise 'Не указан код налога НДС' if tax_type.blank?

      TAX_IDS[tax_type.to_sym] || raise("Не известный код налога НДС #{tax_type}")
    end

    def lines
      order_prices.items.map do |item|
        {
          Qty: item.quantity * MULTIPLICATOR,
          Price: item.price.cents,
          # "PayAttribute": 4,
          TaxId: tax_id(item.tax_type),
          Description: item.title
        }
      end + [delivery_line, package_line]
    end

    def delivery_line
      return if order.delivery_price.zero?

      {
        Qty: 1 * MULTIPLICATOR,
        Price: order_prices.delivery.price.cents,
        # "PayAttribute": 4,
        TaxId: tax_id(order_prices.delivery.tax_type),
        Description: order_prices.delivery.title
      }
    end

    def package_line
      return if order.package_price.zero?

      {
        Qty: 1 * MULTIPLICATOR,
        Price: order_prices.package.price.cents,
        # "PayAttribute": 4,
        TaxId: tax_id(order_prices.package.tax_type),
        Description: order_prices.package.title
      }
    end
  end
end
