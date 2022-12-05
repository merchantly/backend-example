module Bitrix24
  module ProductRow
    def add_product_rows_to_deal(deal_id, order)
      params = {
        id: deal_id
      }

      params[:rows] = order.items.map do |order_item|
        good = order_item.good

        product = good.is_a?(ProductItem) ? good.product : good

        id_product = product_id(product)

        {
          PRODUCT_ID: id_product,
          PRICE: order_item.price.to_f,
          QUANTITY: order_item.count
        }
      end

      url = Bitrix24CloudApi::CRM::DEAL::ProductRows.resource_url(client, 'set')
      JSON.parse(HTTP.post(url, json: params.merge(auth: access_token.access_token)).body)
    end
  end
end
