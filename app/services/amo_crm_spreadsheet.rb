# Пример файла:
# ./doc/import_example_leads_beta_ru.csv

class AmoCrmSpreadsheet < AbstractBaseSpreadsheet
  private

  def encoding
    'cp1251'
  end

  def header_row
    I18n.t('csv.operator.orders.headers').split(',')
  end

  def collection
    @collection.includes(:admin_comments, :items)
  end

  def row(order)
    [
      Order.model_name.human,                       # Название сделки
      order.total_with_delivery_price.to_f,         # Бюджет сделки
      responsible(order),                           # Ответственный за сделку
      I18n.l(order.created_at, format: :amo_csv),   # Дата создания (сделка)
      creator(order),                               # Кем создана сделка
      '',                                           # Тег сделки
      order.admin_comments.first.try(:body),        # Примечание к сделке
      order.admin_comments.second.try(:body),       # Примечание к сделке
      order.admin_comments.third.try(:body),        # Примечание к сделке
      order.admin_comments.fourth.try(:body),       # Примечание к сделке
      order.admin_comments.fifth.try(:body),        # Примечание к сделке
      order.workflow_state.title,                   # Статус сделки
      order.name,                                   # Полное имя (контакт)
      '',                                           # Должность (контакт)
      '',                                           # Рабочий телефон (контакт)
      '',                                           # Домашний телефон (контакт)
      order.phone,                                  # Мобильный телефон (контакт)
      '',                                           # Факс (контакт)
      '',                                           # Другой телефон (контакт)
      '',                                           # Рабочий email (контакт)
      order.email,                                  # Личный email (контакт)
      '',                                           # Другой email (контакт)

      '',                                           # Название (компания)
      "#{order.city_title} #{order.address}",       # Адрес (компания)
      '',                                           # Сайт компании
      '',                                           # Рабочий телефон (компания)
      '',                                           # Мобильный телефон (компания)
      '',                                           # Факс (компания)
      '',                                           # Другой телефон (компания)
      '',                                           # Рабочий email (компания)
      '',                                           # Личный email (компания)
      '',                                           # Другой email (компания)
      '',                                           # ICQ (контакт)
      '',                                           # Jabber (контакт)
      '',                                           # Google Talk (контакт)
      '',                                           # Skype (контакт)
      '',                                           # MSN (контакт)
      '',                                           # Другой IM (контакт)
    ]
  end

  def creator(order)
    responsible(order) || order.name
  end

  def responsible(order)
    order.admin_comments.first.try(:author).to_s
  end
end
