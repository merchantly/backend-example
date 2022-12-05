class OrderItemsExporter
  include Virtus.model

  attribute :vendor, Vendor

  def perform
    CSV.generate do |csv|
      csv << headers

      vendor.orders.ordered.each do |order|
        order.items.each do |item|
          csv << row(item)
        end
      end
    end
  end

  private

  def headers
    I18n.t('csv.operator.orders.item_headers')
  end

  def row(item)
    [
      item.order.local_id,
      item.title,
      item.good.try(:article),
      item.price.to_f,
      item.quantity,
      item.total_price.to_f,
      item.order.client.try(:full_info),
      item.order.created_at,
      item.order.workflow_state.name,
      item.order.order_payment.humanized_state
    ]
  end
end
