module Export
  module FacebookCatalog
    class Csv
      DESCRIPTION_MAX_SIZE = 5000
      TITLE_MAX_SIZE = 100
      IMAGE_MAX_SIZE = 500

      include Virtus.model

      attribute :vendor, Vendor

      def generate
        CSV.generate do |csv|
          csv << headers

          vendor.products.common.published.orderable.find_each do |product|
            if vendor.facebook_catalog_product_items_exported?
              product.goods.each do |good|
                csv << product_row(good) if price(good)
              end
            else
              csv << product_row(product) if price(product)
            end
          end
        end
      end

      private

      def headers
        %i[id availability condition description image_link link title price mpn google_product_category product_type item_group_id additional_image_link]
      end

      def product_row(good)
        [
          product_id(good),
          availability(good),
          condition(good),
          description(good),
          image_link(good),
          link(good),
          title(good),
          price(good),
          mpn(good),
          google_product_category(good),
          product_type(good),
          item_group_id(good),
          additional_image_link(good)
        ]
      end

      def additional_image_link(good)
        good.images.reject { |i| i == good.mandatory_index_image }.map(&:url).join(',')
      end

      def product_id(good)
        good.global_id
      end

      def availability(good)
        good.is_run_out ? 'out of stock' : 'in stock'
      end

      def condition(_good)
        'new'
      end

      def item_group_id(good)
        if good.is_a? ProductItem
          good.product.global_id
        elsif good.is_a?(Product) || good.is_a?(ProductUnion)
          good.global_id
        elsif good.is_part_of_union?
          good.product_union.global_id
        end
      end

      def description(good)
        Rails::Html::Sanitizer.full_sanitizer.new.sanitize(good.description.try(:truncate, DESCRIPTION_MAX_SIZE) || '')
      end

      def image_link(good)
        good.mandatory_index_image.url
      end

      def product_type(good)
        good.category.path.map(&:name).join(' > ') if good.category.present?
      end

      def link(good)
        good.public_url
      end

      def title(good)
        good.title.truncate(TITLE_MAX_SIZE)
      end

      def price(good)
        price = case good
                when ProductUnion
                  good.goods.map(&:actual_price).compact.min
                when ProductItem
                  good.actual_price
                when Product
                  good.items.present? ? good.items.map(&:actual_price).compact.min : good.actual_price
                else
                  raise "Unknown #{good}"
                end

        return if price.nil?

        [price.to_f, price.currency.iso_code].join(' ')
      end

      def mpn(good)
        good.article.presence || good.uuid
      end

      def google_product_category(good)
        good.categories.where.not(google_product_category_id: nil).first.try :google_product_category_id
      end
    end
  end
end
