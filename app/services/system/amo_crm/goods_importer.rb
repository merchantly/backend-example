module System::AmoCRM
  class GoodsImporter < Base
    include Virtus.model strict: true

    attribute :vendor, Vendor
    attribute :catalog_id, Integer # Каталог в потором хранятся товары. 1581 - ID каталога с товарами в f5.kiiiosk.store
    attribute :moysklad_custom_field_id, Integer # Поле в котором хранится ID moysklad 605_687

    def perform
      elements = all_elements 'catalog_elements/list', catalog_id: catalog_id

      update_products elements

      # TODO перехсохранять остальные товары, чтобы обновилсь is_ordering
    end

    def update_products(elements)
      elements.each do |element|
        custom_field = element[:custom_fields].find { |f| f[:id].to_i == moysklad_custom_field_id }

        if custom_field.present?
          moysklad_id = custom_field[:values][0][:value]
          if moysklad_id.present?
            product = vendor.products.find_by(ms_uuid: moysklad_id)

            if product.present?
              unless product.amocrm_catalog_element_id == moysklad_id.to_i
                logger.info "Устанавливаю товару с ms_uuid=#{moysklad_id} amocrm_catalog_element_id=#{element[:id]}"
                product.update_column :amocrm_catalog_element_id, element[:id]
              end
            else
              logger.error "Не найден товар с #{moysklad_custom_field_id}"
            end
          else
            logger.error "Осутствует значение у custom_field #{element[:id]}"
          end
        else
          logger.erorr "У catalog_element #{element[:id]} отсутвует custom_field[id=#{moysklad_custom_field_id}]"
        end
      end
    end

    def logger
      Rails.logger
    end

    def all_elements(path, params)
      key = path.split('/').first
      list = []
      last_pagination = nil
      page = 1
      loop do
        result = amocrm.client.get path, params.merge(PAGEN_1: page)
        raise result[:errors].join(';') if result[:errors].present?

        list += result[key]
        last_pagination = result[:pagination]
        page += 1
        break if page >= last_pagination[:pages][:total]
      end
      logger.warn "Не совпадают количества элементов #{last_pagination[:total]}<>#{list.length}" unless last_pagination[:total] == list.length
      list
    end
  end
end
