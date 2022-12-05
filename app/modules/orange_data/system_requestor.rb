module OrangeData
  class SystemRequestor
    include Virtus.model strict: true

    attribute :invoice, OpenbillInvoice

    CRT_PATH = Rails.root.join('config/orange_data/client.crt')
    KEY_PATH = Rails.root.join('config/orange_data/client.key')
    PRIVATE_PATH = Rails.root.join('config/orange_data/private_key.pem')

    MAX_TEXT_LENGTH = 128

    def perform
      OrangeData.logger.info 'Выполняю запрос..'

      client = OrangeData::Client.new(
        client_cert: File.read(CRT_PATH),
        client_key: File.read(KEY_PATH),
        private_key: File.read(PRIVATE_PATH),
        client_key_password: Secrets.orange_data.client_key_password,
        env: (Rails.env.production? ? :production : :test)
      )
      client.post(data)

      OrangeData.logger.info 'Успешно завершено'
    rescue StandardError => e
      Bugsnag.notify e
      OrangeData.logger.error 'Ошибка'
      raise e
    end

    def data
      {
        id: invoice.id, # Идентификатор документа
        Inn: Settings.orange_data.inn, # ИНН организации, для которой пробивается чек
        key: Settings.orange_data.inn, # Название ключа, который должен быть использован для проверки подпись. Для клиентов используется их ИНН
        # group: 'Main', # Группа устройств, с помощью которых будет пробит чек (default Main)
        content: { # Содержимое документа
          type: 1, # Признак расчета, 1054: 1. Приход 2. Возврат прихода 3. Расход 4. Возврат расхода
          positions: [ # Список предметов расчета, 1059
            {
              quantity: 1.000, # Количество предмета расчета, 1023
              price: invoice.amount.to_f,
              tax: Settings.orange_data.tax, # Ставка НДС, 1199:
              # 1 – ставка НДС 18%
              # 2 – ставка НДС 10%
              # 3 – ставка НДС расч. 18/118
              # 4 – ставка НДС расч. 10/110
              # 5 – ставка НДС 0%
              # 6 – НДС не облагается

              text: invoice.title.truncate(MAX_TEXT_LENGTH), # Наименование предмета расчета, 1030
              paymentMethodType: 4, # Признак способа расчета, 1214:
              # 1 – Предоплата 100%
              # 2 – Частичная предоплата
              # 3 – Аванс
              # 4 – Полный расчет
              # 5 – Частичный расчет и кредит
              # 6 – Передача в кредит
              # 7 – оплата кредита

              paymentSubjectType: 4 # Признак предмета расчета, 1212:
              # 1 – Товар
              # 2 – Подакцизный товар
              # 3 – Работа
              # 4 – Услуга
              # 5 – Ставка азартной игры
              # 6 – Выигрыш азартной игры
              # 7 – Лотерейный билет
              # 8 – Выигрыш лотереи
              # 9 – Предоставление

              # Необязательные поля
              # nomenclatureCode: Код товарной номенклатуры, 1162
              # supplierInfo: Данные поставщика, 1224 { phoneNumbers: 'телефон', name: 'Наименование'}
              # supplierINN: ИНН поставщика, 1226
            }
          ],
          checkClose: { # Параметры закрытия чека
            payments: [
              {
                type: Settings.orange_data.payment_type, # Тип оплаты: 1 – сумма по чеку наличными, 1031
                #             2 – сумма по чеку электронными, 1081
                #             14 – сумма по чеку предоплатой (зачетом аванса и (или) предыдущих платежей), 1215
                #             15 – сумма по чеку постоплатой (в кредит), 1216
                #             16 – сумма по чеку (БСО) встречным предоставлением, 1217

                amount: invoice.amount.to_f # Сумма оплаты
              }
            ],
            taxationSystem: Settings.orange_data.taxation_system # Система налогообложения, 1055:
            # 0 – Общая, ОСН
            # 1 – Упрощенная доход, УСН доход
            # 2 – Упрощенная доход минус расход, УСН доход - расход
            # 3 – Единый налог на вмененный доход, ЕНВД
            # 4 – Единый сельскохозяйственный налог, ЕСН
            # 5 – Патентная система налогообложения, Патент
          },
          customerContact: client_email_or_phone # Телефон или электронный адрес покупателя, 1008

          # Необязательные поля
          # agentType: Признак агента, 1057. Битовое поле, где номер бита обозначает, что оказывающий услугу покупателю (клиенту) пользователь является:
          # 0 – банковский платежный агент
          # 1 – банковский платежный субагент
          # 2 – платежный агент
          # 3 – платежный субагент
          # 4 – поверенный
          # 5 – комиссионер
          # 6 – иной агент
          # paymentTransferOperatorPhoneNumbers: Телефон оператора перевода, 1075
          # paymentAgentOperation: Телефон платежного агента, 1073
          # paymentOperatorPhoneNumbers: Телефон оператора по приему платежей, 1074
          # paymentOperatorName: Наименование оператора перевода, 1026
          # paymentOperatorAddress: Адрес оператора перевода, 1005
          # paymentOperatorINN: ИНН оператора перевода, 1016
          # supplierPhoneNumbers: Телефон поставщика, 1171
          # additionalUserAttribute: Дополнительный реквизит пользователя, 1084 {name: 'Наименование', value: 'Значение'}
        }
      }
    end

    def client
      owner = invoice.vendor.owners.first
      return owner if owner.present?

      Bugsnag.notify "У вендора #{invoice.vendor.host} нет owners", metaData: { vendor_id: invoice.vendor.id }
      nil
    end

    def client_email_or_phone
      return if client.blank?
      return client.email.to_s if client.email.present?
      return client.phone.to_s if client.phone.present?
    end
  end
end
