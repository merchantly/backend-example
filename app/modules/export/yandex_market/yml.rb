# https://yandex.ru/support/partnermarket/yml/about-yml.xml?lang=ru
# Генератор xml файла для яндекс маркета

module Export
  module YandexMarket
    class Yml < BaseExportYml
      include ActionView::Helpers::SanitizeHelper
      # Элемент <delivery-options> может содержать до пяти элементов <option>
      # для указания разных типов и условий доставки (например, обычная, экспресс и т. п.).
      DELIVERY_LIMIT = 5
      IMAGES_LIMIT = 10

      AGENCY = 'kiiiosk.store'.freeze

      def generate
        Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
          xml.doc.create_internal_subset('yml_catalog', nil, 'shops.dtd')
          xml.yml_catalog(date: Time.zone.now.strftime(DATE_FORMAT)) do
            xml.shop do
              shop(xml)
              currencies(xml)
              categories(xml)
              delivery_options(xml)
              offers(xml)
            end
          end
        end
      end

      private

      def shop(xml)
        xml.url vendor_root_url(host: vendor.home_url)
        xml.name vendor.name
        xml.email Settings.support_email
        xml.agency AGENCY
        xml.company vendor.yandex_market_company
      end

      def currencies(xml)
        xml.currencies do
          xml.currency(id: vendor.currency_iso_code, rate: 1)
        end
      end

      def categories(xml)
        xml.categories do
          vendor.categories.alive.each do |category|
            opts = { id: category.id }
            opts[:parentId] = category.parent.id if category.parent.present? && category.parent.alive?
            xml.category(opts) { xml << category.name }
          end
        end
      end

      def delivery_options(xml)
        xml.send('delivery-options') do
          vendor.available_delivery_types.limit(DELIVERY_LIMIT).each do |delivery|
            xml.option(cost: delivery.price)
          end
        end
      end

      def offers(xml)
        xml.offers do
          products.find_each do |product|
            next unless product.has_any_price?

            xml.offer(id: product.id, available: true) do
              offer_product xml, product if product.min_price.present? && product.category_ids.present?
            end
          end
        end
      end

      def offer_product(xml, product)
        xml.url vendor_product_url(product, host: vendor.home_url)
        xml.name product.name

        if product.min_price == product.max_price
          xml.price product.min_price
        else
          xml.price product.min_price, from: true
        end

        xml.oldprice(product.price) if !product.is_union && product.is_sale?

        xml.currencyId product.min_price.currency

        # Обычно отдают одну категорию, но вроде не запрещено отдавать
        # несколько. Добавлено попросьбе честной ферсы
        vendor.categories.where(id: product.category_ids).alive.pluck(:id).each do |cid|
          xml.categoryId cid
        end

        xml.pickup delivery_has_pickup?
        xml.description strip_tags product.description
        product.images.limit(IMAGES_LIMIT).each do |image|
          xml.picture image.image.url
        end
      rescue StandardError => e
        binding.debug_error
        Bugsnag.notify e, metaData: { vendor_id: vendor.id, product_id: product.id }
        raise e
      end
    end
  end
end
