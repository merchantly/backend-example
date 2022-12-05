module Bitrix24
  module Deal
    def add_deal(order)
      return order.bitrix24_id if order.bitrix24_id.present?

      params = {
        fields: {
          TITLE: "Заказ ##{order.id}",
          STAGE_ID: deal_stage(order),
          TYPE_ID: 'GOODS',
          IS_NEW: 'Y',
          OPENED: 'Y',
          CURRENCY_ID: order.currency,
          OPPORTUNITY: order.total_price.to_f,
          DATE_CREATE: order.created_at.strftime('%Y-%m-%dT%H:%M:%S+03:00'),
          COMMENTS: deal_comments(order),
          ORIGINATOR_ID: order.operator_url,
          ASSIGNED_BY_ID: manager_id(vendor_bitrix24.responsible_manager),
          COMPANY_ID: company_id(order.client)
        }
      }

      result = Bitrix24CloudApi::CRM::Deal.add(client, params)

      raise "Ошибка добавления сделки в bitrix24: #{result}" if result['error_description'].present?

      order.update_column :bitrix24_id, result['result']

      add_product_rows_to_deal(order.bitrix24_id, order)

      order.bitrix24_id
    end

    def deal_stage(_order)
      'NEW'
    end

    def deal_comments(order)
      comments = ''
      comments << "#{order.comment}<br><br>" if order.comment.present?
      comments << "#{details_prices(order)}<br><br>"
      comments << "#{details_delivery(order)}<br><br>"
      comments << "#{product_urls(order)}<br><br>"
    end

    def details_prices(order)
      order.items.map { |oi| "#{oi.good.name}: #{oi.price.to_f} * #{oi.count} = #{oi.total_price.to_f} #{order.currency}" }.join('<br>') + "<br>Общая сумма: #{order.total_price.to_f} #{order.currency}"
    end

    def product_urls(order)
      order.items.map { |oi| "#{oi.good.name}: #{product_url(oi.good)}" }.join('<br>')
    end

    def product_url(good)
      Rails.application.routes.url_helpers.vendor_product_url(id: good, host: good.vendor.home_url)
    end

    def details_delivery(order)
      "Способ доставки: #{order.delivery_type.title}<br>Адрес доставки: #{order.full_address}"
    end
  end
end
