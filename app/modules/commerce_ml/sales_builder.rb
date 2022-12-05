require 'nokogiri'

# В 1С
# https://www.cs-cart.ru/docs/4.3.x/_downloads/orders_1C.xml
#
# Из 1С
# https://www.cs-cart.ru/docs/4.3.x/_downloads/orders-42a0dc7a-d94f-462a-a20f-0e09261f4c9d.xml
#
# Пример:
# https://www.cs-cart.ru/docs/4.3.x/developer/1c/ordersxml.html#id4
# https://www.cs-cart.ru/docs/4.3.x/developer/1c/catalogxml.html
# https://dev.1c-bitrix.ru/learning/course/?COURSE_ID=42&LESSON_ID=3644
#
# Поле "Адрес доставки" не заполнено
# Поле "Договор" не заполнено
# Поле "Способ доставки" не заполнено
# Поле "Перевозчик" не заполнено
# Поле "Адрес доставки перевозчика" не заполнено
#
class CommerceML::SalesBuilder
  CURRENCIES = {
    'RUB' => 'руб',
    'USD' => 'usd',
    'EUR' => 'eur'
  }.freeze

  def initialize(orders)
    @orders = orders
  end

  def build_none
    Nokogiri::XML::Builder.new encoding: encoding do |xml|
      xml.КоммерческаяИнформация ВерсияСхемы: '2.03', ДатаФормирования: build_date do
      end
    end
  end

  def build
    Nokogiri::XML::Builder.new encoding: encoding do |xml|
      xml.КоммерческаяИнформация ВерсияСхемы: '2.03', ДатаФормирования: build_date do
        orders.each do |order|
          xml.Документ do
            xml.Ид order.id
            xml.Номер number(order)
            xml.Дата date_format order.created_at
            xml.Время time_format order.created_at
            xml.ХозОперация 'Заказ товара'
            xml.Роль 'Продавец'
            xml.Валюта order_currency(order.currency.to_s)
            # xml.Курс order.currency_rate # ?
            xml.Сумма order.total_price.to_f
            xml.Комментарий order_comment(order)
            xml.Контрагенты do
              xml.Контрагент do
                xml.Ид order.client.id
                xml.Наименование order.client.name
                xml.Роль 'Покупатель'

                xml.ПолноеНаименование order.client.name
                xml.Фамилия order.client.last_name
                xml.Имя order.client.first_name

                xml.Адрес do
                  xml.Представление order.client.address
                end
                xml.АдресРегистрации do
                  xml.Представление order.client.address
                end
                xml.Контакты do
                  xml.Контакт do
                    xml.Тип 'Телефон рабочий'
                    xml.Значение order.client.phone
                  end
                  xml.Контакт do
                    xml.Тип 'Почта'
                    xml.Значение order.client.email
                  end
                end
                # xml.Представители {
                # xml.Представитель {
                # xml.Контрагент {
                # xml.Отношение 'Контактное лицо'
                # xml.Ид order.user.id
                # xml.Наименование 'Покупатель'
                # }
                # }
                # }
              end
            end
            xml.Товары do
              order.items.each do |item|
                xml.Товар do
                  xml.Ид item.good.article
                  # xml.Артикул
                  xml.Наименование item.good.title
                  xml.БазоваяЕдиница 'шт', Код: '796', НаименованиеПолное: 'Штука', МеждународноеСокращение: 'PCE'
                  xml.ЦенаЗаЕдиницу item.price.to_f
                  xml.Количество item.count
                  xml.Сумма item.total_price.to_f

                  xml.ЗначенияРеквизитов do
                    xml.ЗначениеРеквизита do
                      xml.Наименование 'Дата отгрузки'
                      xml.Значение date_format(Time.zone.now)
                    end
                    xml.ЗначениеРеквизита do
                      xml.Наименование 'ВидНоменклатуры'
                      xml.Значение 'Товар'
                    end
                    xml.ЗначениеРеквизита do
                      xml.Наименование 'ТипНоменклатуры'
                      xml.Значение 'Товар'
                    end
                  end
                end
              end
            end
            xml.ЗначенияРеквизитов do
              order_attributes(order).each_pair do |key, value|
                xml.ЗначениеРеквизита do
                  xml.Наименование key
                  xml.Значение value
                end
              end
            end
          end
        end
      end
    end
  end

  private

  attr_reader :orders

  def order_attributes(order)
    {
      'Метод оплаты' => order.payment_type.to_s,
      'Заказ оплачен' => order.paid?,
      'Доставка разрешена' => true,
      'Отменен' => order.failure?,
      'ДатаСайт' => '2017-05-05',
      'НомерСайт' => 123,
      'Номер по 1С' => number(order),
      'Дата по 1С' => date_time_format(order.created_at),
      'Финальный статус' => false,
      'Статус заказа' => '[N] Принят',
      'Дата изменения статуса' => date_time_format(order.updated_at),
      'Адрес доставки' => order.full_address,
      'Способ доставки' => order.delivery_type.title,
      'АдресДоставки' => order.full_address,
      'СпособДоставки' => order.delivery_type.title,
      'Адрес' => order.full_address,
      'Телефон' => order.phone,
      'ФИО' => order.full_name,
      'Cтатус оплаты' => I18n.t(order.order_payment.state, scope: %i[activerecord attributes order payment_states])
    }
  end

  def order_currency(currency)
    CURRENCIES[currency] || raise("Неизвестная валюта #{currency}")
  end

  def date_time_format(time)
    time.strftime('%Y-%m-%d %H:%M:%S')
  end

  def time_format(time)
    time.strftime('%H:%M:%S')
  end

  def date_format(date)
    date.strftime('%Y-%m-%d')
  end

  def build_date
    date_format Time.zone.today
  end

  def order_comment(order)
    "#{order.comment}\n\nСпособ доставки: #{order.delivery_type.title}\nАдрес доставки:#{order.full_address}"
  end

  def number(order)
    prefix(order)
  end

  def prefix(order)
    if Rails.env.production?
      "#{order.vendor.domain}-#{order.id}"
    else
      "TEST-#{order.vendor.domain}-#{order.id}"
    end
  end

  def encoding
    # 'cp1251'
    'utf-8'
  end
end
