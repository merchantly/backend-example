module RussianPost
  class Requestor
    include Virtus.model strict: true

    attribute :order, Order

    def perform
      RussianPost.logger.info "Выполняю запрос по заказу #{order.id}.."
      client = RussianPost::Client.new(
        token: order.delivery_type.russian_post_token,
        key: order.delivery_type.russian_post_key
      )

      res = JSON.parse client.post(data).body

      RussianPost.logger.info "Результат: #{res}"

      check_errors res

      russian_post_id = res['result-ids'].first

      order.order_delivery.update! external_id: russian_post_id.to_i, error: nil

      RussianPost.logger.info "Заказ #{order.id}. Результат: #{res}"
    rescue DaDataError::UndeterminedAddress => e
      RussianPost.logger.error "Заказ #{order.id}. Ошибка: недостаточно информации из адреса {order.address}"
      raise e
    rescue StandardError => e
      Bugsnag.notify e, metaData: { order_id: order.id }
      RussianPost.logger.error "Заказ #{order.id}. Ошибка: #{e}"
      order.order_delivery.cancel_with_error!(e.to_s)
      order.vendor.bells_handler.add_error e, error: e.to_s if e.is_a?(RussianPost::ResponseError)
      raise e
    end

    private

    def data
      order_data = {
        'order-num': order.public_id,
        'brand-name': order.vendor.name, # Отправитель на посылке/название брэнда
        'address-type-to': 'DEFAULT', # Тип адреса: DEFAULT - Стандартный (улица, дом, квартира), PO_BOX - Абонентский ящик, DEMAND - До востребования
        'given-name': order.first_name, # Имя получателя

        'region-to': order.region, # регион
        'place-to': order.city_to_delivery, # Населенный пункт
        'street-to': order.street, # улица
        'house-to': order.house, # Номер здания
        'slash-to': (order.slash unless order.slash.to_i.zero?), # Дробь
        'index-to': order.postal_code, # почтовый индекс
        'room-to': order.room, # квартира/комната

        'mail-category': mail_category, # Категория РПО
        'mail-direct': mail_direct, # Код страны
        'mail-type': mail_type,

        mass: mass_gram, # Вес РПО (в граммах) (обязательно)
        # "dimension": order.dimension.to_h, # Линейные размеры (необязательно)

        'payment-method': 'CASHLESS',

        surname: order.second_name,
        'tel-address': order.phone.to_s,

        fragile: order.delivery_type.fragile.to_s # Установлена ли отметка 'Осторожно/Хрупкое'?
      }

      order_data['insr-value'] = order.total_price.exchange_to('RUB').cents if RussianPost::INSURANCE_VALUE_REQUIRE.include?(mail_category)
      order_data['payment'] = order.total_price.exchange_to('RUB').cents if RussianPost::PAYMENT_REQUIRE.include?(mail_category)
      order_data['postoffice-code'] = postoffice_code if postoffice_code.present?

      [order_data]
    end

    def mail_category
      order.delivery_type.russian_post_mail_category
    end

    def mail_direct
      order.delivery_type.russian_post_mail_direct
    end

    def mail_type
      order.delivery_type.russian_post_mail_type
    end

    def postoffice_code
      order.delivery_type.russian_post_postoffice_code
    end

    def mass_gram
      return order.delivery_type.default_weight_gr if order.weight.zero?

      order.weight * 1000
    end

    def check_errors(res)
      if res['errors'].present?
        message = res['errors'].first['error-codes'].map { |error_code| error_code['description'] }.join(', ')

        raise RussianPost::ResponseError.new(message)
      end

      if res['status'] == 'ERROR'
        raise RussianPost::ResponseError.new(res['message'])
      end

      if res['code'] == '1011'
        raise RussianPost::ResponseError.new(res['desc'])
      end

      if res['result-ids'].blank?
        raise RussianPost::ResponseError.new(res)
      end
    end
  end
end
