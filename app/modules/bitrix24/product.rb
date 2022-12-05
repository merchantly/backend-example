module Bitrix24
  module Product
    def product_id(product)
      if product.bitrix24_id.present?
        result = update_product(product)
        raise "Ошибка обновления продукта в bitrix24: #{result}" if result['error_description'].present?

        return product.bitrix24_id
      end

      result = add_product(product)

      raise "Ошибка добавления продукта в bitrix24: #{result}" if result['error_description'].present?

      bitrix24_id = result['result']

      product.update_column(:bitrix24_id, result['result'])

      bitrix24_id
    end

    def product_params(product)
      {
        fields: {
          NAME: product.name,
          CURRENCY_ID: product.price_currency,
          PRICE: product.actual_price.to_f
        }
      }
    end

    def add_product(product)
      Bitrix24CloudApi::CRM::Product.add(client, product_params(product))
    end

    def update_product(product)
      Bitrix24CloudApi::CRM::Product.update(client, product_params(product).merge(id: product.bitrix24_id))
    end
  end
end
