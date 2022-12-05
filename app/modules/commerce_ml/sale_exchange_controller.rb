# Протокол обмена: http://v8.1c.ru/edi/edi_stnd/131/
#
module CommerceML
  #
  # Последовательность действий при работе с заказом
  #
  # 1. Заказ оформляется на сайте
  # 2. При передаче в систему "1С:Предприятие" в заказе устанавливается категория "Заказ с сайта".
  # При формировании заказа в системе "1С:Предприятие" записываются номер и дата заказа, с которыми он оформлен на сайте. Поиск контрагента осуществляется по ИНН или наименованию, в зависимости от указанных настроек.
  # 3. При загрузке заказа производится поиск договора с контрагентом. Договор ищется среди существующих договоров с клиентом, с признаком ведения взаиморасчетов по заказам (по указанной в настройках загрузки Организации). Если не находится ни один договор, то создается новый.
  # 4. При загрузке заказа загружаются все его свойства, переданные с сайта. Свойства ищутся в системе "1С:Предприятие" по наименованию. Если с таким наименованием свойства нет, то заводится новое свойство со значениями типа строка или число.
  # 5. Заказ может модифицироваться в системе "1С:Предприятие", при этом его изменения будут выгружаться на сайт
  # 6. Если заказ оплачивается или отгружается в системе "1С:Предприятие", то состояния заказа по оплате и по отгрузке выгружаются на сайт только при полном выполнении операции (полной оплате и полной отгрузке). До этого момента заказ считается не оплаченным и не отгруженным.
  # 7. При попытке в системе "1С:Предприятие" изменить заказ, по которому произведена оплата или отгрузка, заказ на сайт не загрузится как измененный. При этом пользователь получит об этом сообщение.
  # 8. После каждой выгрузка заказа на сайт, на стороне сайта определяются значения его категорий (ссылка на категории). Эти значения устанавливаются в системе  "1С:Предприятие" так, как они присвоены заказу на сÐ°йте
  #
  class SaleExchangeController < BaseExchangeController
    # C. Получение файла обмена с сайта
    #
    # Затем на сайт отправляется запрос вида
    # http://<сайт>/<путь> /1c_exchange.php?type=sale&mode=query.
    #
    # Сайт передает сведения о заказах в формате CommerceML 2.
    def query
      CommerceML.logger.info "query vendor_id=#{current_vendor.id}"

      exchange_record.update_status! :query
      exchange_record.update_export_status! :query
      file_path = "./public/#{current_vendor.id}-sales.xml"
      File.write(file_path, sales_xml.to_xml(encoding: 'utf-8'))
      send_file file_path
    end

    # В случае успешного получения и записи заказов "1С:Предприятие" передает на сайт запрос вида
    # http://<сайт>/<путь> /1c_exchange.php?type=sale&mode=success
    #

    def success
      CommerceML.logger.info "success vendor_id=#{current_vendor.id}"

      exchange_record.success!
      exchange_response 'succcess'
    end

    def import
      CommerceML.logger.info "import vendor_id=#{current_vendor.id}"

      exchange_response 'failure'
    end

    private

    def sales_xml
      CommerceML::SalesBuilder.new(exchange_record.orders).build
    end

    def orders_to_export
      current_vendor
        .orders
        .where('created_at>?', configuration.start_export_at)
        .where('id not in (select order_id from exchange_record_sales where is_exported)')
        .limit(configuration.sales_limit)
    end

    def create_exchange_record
      exchange_record = exchange_record_class.create!
      orders_to_export.each do |o|
        exchange_record.sales.create! order: o
        CommerceML.logger.info "Добавить заказ в экспорт #{o.id}"
      end

      exchange_record
    end

    def exchange_record_class
      ExchangeSaleRecord
    end
  end
end
