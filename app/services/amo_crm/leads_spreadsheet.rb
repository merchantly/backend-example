# экспорт вендоров в два CSV файла для AmoCRM в active admin
module AmoCrm
  class LeadsSpreadsheet < AmoCrm::BaseSpreadsheet
    private

    def header_row
      'Название сделки,Бюджет сделки,Ответственный за сделку,Дата создания (сделка),Кем создана сделка,Тег сделки,Примечание к сделке,Примечание к сделке,Примечание к сделке,Примечание к сделке,Примечание к сделке,Статус сделки,Полное имя (контакт),Должность (контакт),Рабочий телефон (контакт),Домашний телефон (контакт),Мобильный телефон (контакт),Факс (контакт),Другой телефон (контакт),Рабочий email (контакт),Личный email (контакт),Другой email (контакт),Название (компания),Адрес (компания),Сайт компании,Рабочий телефон (компания),Мобильный телефон (компания),Факс (компания),Другой телефон (компания),Рабочий email (компания),Личный email (компания),Другой email (компания),ICQ (контакт),Jabber (контакт),Google Talk (контакт),Skype (контакт),MSN (контакт),Другой IM (контакт)'.split(',')
    end

    def row(vendor)
      [
        'Первая абонентская плата',                   # Название сделки
        '1000',                                       # Бюджет сделки
        manager(vendor),                              # Ответственный за сделку
        I18n.l(vendor.created_at, format: :amo_csv),  # Дата создания (сделка)
        'auto',                                       # Кем создана сделка
        'shop',                                       # Тег сделки
        '',                                           # Примечание к сделке
        '',                                           # Примечание к сделке
        '',                                           # Примечание к сделке
        '',                                           # Примечание к сделке
        '',                                           # Примечание к сделке
        lead_status(vendor),                          # Статус сделки
        full_name(vendor),                            # Полное имя (контакт)
        '',                                           # Должность (контакт)
        phone(vendor),                                # Рабочий телефон (контакт)
        '',                                           # Домашний телефон (контакт)
        phone(vendor),                                # Мобильный телефон (контакт)
        '',                                           # Факс (контакт)
        '',                                           # Другой телефон (контакт)
        email(vendor),                                # Рабочий email (контакт)
        email(vendor),                                # Личный email (контакт)
        '',                                           # Другой email (контакт)
        clean_string(vendor.name),                    # Название (компания)
        '',                                           # Адрес (компания)
        vendor.host,                                  # Сайт компании
        phone(vendor),                                # Рабочий телефон (компания)
        phone(vendor),                                # Мобильный телефон (компания)
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

    def phone(vendor)
      buffer = vendor.owners.first.try(:phone) || vendor.phone
      return '' if buffer.blank?

      "+#{buffer}"
    end
  end
end
