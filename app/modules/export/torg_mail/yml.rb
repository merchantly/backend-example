# Генератор xml файла для torg mail
#
# Описание формата и тонкости:
#   http://torg.mail.ru/info/122/
# Пример заполненного XML:
#   http://dem.mymerchium.ru/users/8539/files/1/export_mailru.xml

module Export
  module TorgMail
    class Yml < BaseExportYml
      def generate
        Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
          xml.torg_price(date: Time.zone.now.strftime(DATE_FORMAT)) do
            xml.shop do
              shop(xml)
              currencies(xml)
              categories(xml)
              xml.pickup delivery_has_pickup?
              xml.delivery has_delivery?
              delivery_options(xml)
              offers(xml)
            end
          end
        end
      end

      private

      def shop(xml)
        xml.url vendor_root_url
        xml.name vendor.name
        xml.company vendor.torg_mail_company
      end

      def currencies(xml)
        xml.currencies do
          xml.currency(id: vendor.currency_iso_code, rate: 1)
        end
      end

      def categories(xml)
        xml.categories do
          vendor.categories.each do |category|
            opts = { id: category.id }
            opts[:parentId] = category.parent.id if category.parent.present?
            xml.category(opts) { xml << category.name }
          end
        end
      end

      def delivery_options(xml)
        xml.delivery_options do
          vendor.available_delivery_types.each do |delivery|
            xml.option(cost: delivery.price)
          end
        end
      end

      def offers(xml)
        xml.offers do
          products.find_each do |product|
            xml.offer(id: product.id, available: true) do
              xml.url vendor_product_url(product)
              xml.name product.name
              xml.price product.price
              xml.currencyId(product.price.try(:currency) || vendor.default_currency)
              xml.categoryId product.category_id
              xml.description ActionController::Base.helpers.strip_tags(product.description)
              product.images.each do |image|
                xml.picture image.image.url
              end
            end
          end
        end
      end
    end
  end
end
