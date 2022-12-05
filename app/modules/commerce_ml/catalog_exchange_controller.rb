# Протокол обмена: http://v8.1c.ru/edi/edi_stnd/131/
#
module CommerceML
  #
  # Данные для публикации на сайте выгружаются одним пакетом.
  #
  class CatalogExchangeController < BaseExchangeController
    # Все действия предопределены в базовом контроллере
    # Тут определяем только класс модели

    private

    def create_exchange_record
      exchange_record_class.create!
    end

    def exchange_record_class
      ExchangeCatalogRecord
    end
  end
end
