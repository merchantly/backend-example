require 'open-uri'

module MoyskladImporting
  class GoodsUpdater < Updater
    include BuilderCustomAttributes

    private

    def finish
      if @price_types.nil?
        vendor_logger.warn message: 'В товарах не найдены цены'
      else
        vendor_logger.info message: "В товарах найдены следующие виды цен: #{@price_types.to_a.join('; ')}"
        vendor.update_column :stock_price_types, @price_types.to_a
      end
    end

    def add_price_type(price_type)
      @price_types ||= Set.new
      @price_types << price_type
    end

    def handle_error(entity, e)
      if e.record.errors.one? && e.record.errors.include?(:externalcode)
        exist_record = scope.find_by(externalcode: e.record.externalcode)

        message = "В базе уже присутствует запись с externalcode=#{e.record.externalcode}: [#{exist_record.id}] #{exist_record.title} uuid:#{exist_record.ms_uuid}"
      else
        message = e
      end
      super entity, message
    end

    def resource
      @resource ||= build_resource
    end

    def build_resource
      # Кешируем
      vendor.moysklad_universe.currencies.cache!
      vendor.update_column :ms_currencies_dump, vendor.moysklad_universe.currencies.all.to_json

      all = vendor.moysklad_universe.products.all expand: :productFolder
      all += vendor.moysklad_universe.bundles.all expand: :productFolder
      all += vendor.moysklad_universe.services.all expand: :productFolder

      all
    end

    def scope(_good_entity = nil)
      vendor.products
    end

    def archive_scope
      super.as_product
    end

    def build_model(entity)
      model = build_scope(entity).build

      model.is_manual_published = false unless vendor.autopublicate_goods_from_stock?

      model
    end

    def find_currency(currency)
      moysklad_currency = vendor.moysklad_universe.currencies.find currency.id

      if moysklad_currency.blank?
        vendor_logger.error message: "Валюта с id #{currency.id} не найдена (может в архиве?), возвращаю валюту по-умолчанию"

        return vendor.default_currency
      end

      # Вообще должно быть в isoCode, но у некоторым там 'RUB' вместо цифры
      cur = Money::Currency.find_by_iso_numeric(moysklad_currency.code) ||
        Money::Currency.find(moysklad_currency.code)

      return cur if cur.present?

      vendor_logger.error message: "Не найдена валюта #{moysklad_currency}, возвращаю валюту по-умолчанию"

      vendor.default_currency
    end

    GOOD_TYPES = {
      Moysklad::Entities::Product => 0,
      Moysklad::Entities::Service => 1,
      Moysklad::Entities::Bundle => 2
    }.freeze

    def good_type(entity)
      GOOD_TYPES[entity.class] || raise("Не известный тип entity #{entity.class} #{entity}")
    end

    # @good_entity = Moysklad::Entities::Product, Service, Bundle
    def default_attributes(good_entity, model)
      attrs = {
        stock_title: good_entity.name,
        stock_description: good_entity.description,
        article: good_entity.try(:article),
        volume: good_entity.try(:volume),
        weight: good_entity.try(:weight),
        is_serial_trackable: good_entity.try(:isSerialTrackable),
        code: good_entity.code.presence,
        externalcode: good_entity.externalCode,
        is_service: good_entity.is_a?(Moysklad::Entities::Service),
        good_type: good_type(good_entity)
      }

      attrs[:custom_attributes] = build_custom_attributes_for_product(good_entity) if good_entity.is_a? Moysklad::Entities::Product

      # если в моемскладе не будет приемки товаров(т.е. остатки будут отсутствовать)
      # то товар будет считаться бесконечным, для склада такого поведения не нужно
      if model.quantity.nil? # TODO сделать опциональной настройкой?
        attrs.merge!(
          quantity: 0,
          stock: 0,
          reserve: 0
        )
      end

      category = prefered_category good_entity, model

      if category.present?
        vendor_logger.debug message: "\tПрименяем категорию: #{good_entity.id} - #{category}"
        attrs[:category] = category
      end

      super.merge attrs
    end

    def create_or_update(entity)
      model = super entity

      entity.salePrices.each do |p|
        add_price_type p.priceType

        add_price(model, entity, p)
      end

      model
    end

    def add_price(model, entity, ms_price)
      check_default_price_kinds ms_price.priceType

      price_kind = find_or_create_price_kind ms_price.priceType

      product_price = model.product_prices.find_or_create_by!(price_kind: price_kind)

      currency = find_currency ms_price.currency

      price = if ms_price.value.positive?
                Money.new(ms_price.value, currency)
              else
                vendor_logger.info message: "У товара #{entity.id} цена (#{ms_price.priceType}) меньше или равна нулю (#{ms_price.value} #{ms_price.priceType})"
                nil
              end

      if price.present? && (price.currency != vendor.default_currency)
        vendor_logger.info message: I18n.t('errors.product.price.currencies_conflict', product_currency: price.currency, vendor_currency: vendor.default_currency)
        price = nil
      end

      model.update! is_sale: price.to_f.positive? if price_kind.sale?

      product_price.price = price
      product_price.save! if product_price.changed?
    end

    def check_default_price_kinds(price_type)
      if (vendor.default_price_kind.ms_price_name != price_type) && Regexp.new(vendor.ms_common_price_name, true).match(price_type)
        vendor.price_kinds.find_by(ms_price_name: price_type).try :destroy!

        vendor.default_price_kind.update! ms_price_name: price_type
      end

      if (vendor.sale_price_kind.ms_price_name != price_type) && Regexp.new(vendor.ms_sale_price_name, true).match(price_type)
        vendor.price_kinds.find_by(ms_price_name: price_type).try :destroy!

        vendor.sale_price_kind.update! ms_price_name: price_type
      end
    end

    def find_or_create_price_kind(price_type)
      vendor.price_kinds.create_with(title: price_type).find_or_create_by!(ms_price_name: price_type)
    end

    def update_from_moysklad(model, entity)
      # У Moysklad::Entities::Service нет image
      add_image model, entity.image if vendor.ms_import_images? && entity.try(:image).present?

      super model, entity
    end

    def add_image(model, image)
      vendor_logger.info message: "Загружаю изображение #{image.filename} (#{image.size}) #{image.meta.href} для товара #{model.id}"
      product_image = model.product_images.find_by(ms_uuid: image.meta.id)

      if model.persisted? && product_image.present?
        if model.image_ids.include?(product_image.id)
          vendor_logger.info message: "Изображение с таким ID #{image.meta.id} у товара #{model.id} уже есть. Отменяю загрузку."
        else
          vendor_logger.warn message: "Изображение с таким ID #{image.meta.id} не присоеденино к товару #{model.id}. Присоединяю."
          model.image_ids = model.image_ids + [product_image.id]
        end
      else
        download_and_attach_image(model, image)
      end
    end

    def download_and_attach_image(model, image)
      ext = File.extname image.filename

      download = URI.parse(image.meta.href).open(http_basic_authentication: [vendor.moysklad_login, vendor.moysklad_password])

      file = Tempfile.new [SecureRandom.hex, ext]
      file.close

      IO.copy_stream download, file.path

      raise "Размер загруженного изображения не совпадает с источником (#{file.size} <> #{image.size})" unless file.size == image.size

      product_image = model.product_images.create!(
        vendor: vendor,
        title: image.title,
        filename: image.filename,
        stock_synced_at: synced_at,
        ms_uuid: image.meta.id,
        saved_remote_image_url: image.meta.href,
        image: file
      )
      model.create_moysklad_object! stock_dump: image.dump.to_json

      model.image_ids = model.image_ids + [product_image.id]
    ensure
      file&.unlink
    end

    def prefered_category(good_entity, model)
      return find_ms_category good_entity if vendor.is_stock_do_sync_categories?

      if vendor.prefer_stock_category_when_syncing?
        category = safe_find_ms_category(good_entity)
        return category if category.present?
      end

      return nil if model.try(:category).present?

      vendor.default_import_category
    end

    def safe_find_ms_category(good_entity)
      return if good_entity.productFolder.blank?

      raise "Нет externalCode у группы товара #{good_entity.id}" if good_entity.productFolder.externalCode.blank?

      category = vendor.categories.by_externalcode(good_entity.productFolder.externalCode).take
      return category if category.present?

      vendor_logger.warn message: "У товара #{good_entity.id} не найдена категория"
      nil
    end

    def find_ms_category(good_entity)
      if good_entity.productFolder.present?
        category = safe_find_ms_category good_entity
        if category.blank?
          raise MoyskladImporting::Errors::NoLocalRelationFound.new(good_entity, good_entity.productFolder, :category)
        end
      else
        vendor_logger.warn message: "У товара #{good_entity.id} не установлена категория. Применяем вариант по-умолчанию (#{vendor.default_import_category})."

        category = vendor.default_import_category
      end

      category
    end
  end
end
