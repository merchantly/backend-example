# Update order by operator
class OrderUpdater
  def initialize(order_form, order, current_operator)
    @order = order
    @order_form = order_form
    @current_operator = current_operator
  end

  def perform
    order.with_lock do
      order.update! params
      order.update_prices! if params.keys.include?(:custom_delivery_price)

      if order.previous_changes.present?
        order.author = current_operator
        message = changes_message(order)
        order.log! :order_attrs_updated, attrs: message if message.present?
      end
    end

    order
  end

  private

  attr_reader :order, :order_form, :current_operator

  def changes_message(order)
    order.previous_changes.slice(*params.keys).map do |attr, values|
      "#{attr}: #{values.join(' -> ')}"
    end.join(',')
  end

  def params
    order_form.allowed_update_order_attributes
  end
end
