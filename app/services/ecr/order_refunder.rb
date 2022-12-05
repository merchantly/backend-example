class Ecr::OrderRefunder
  Error = Class.new StandardError

  def initialize(order:, items:, operator:)
    @order = order
    @items = items
    @operator = operator
  end

  def self.perform(order:, items:, operator:)
    new(order: order, items: items, operator: operator).perform
  end

  def perform
    raise Error, "Sale document is empty for order: #{order.id}" if sale_document.blank?

    validate! items

    order.with_lock do
      amount = vendor.zero_money

      items.each do |item|
        amount += item[:order_item].order_price.price * item[:quantity]
      end

      form = Ecr::DocumentForm::Refund.new(
        vendor: vendor,
        document_id: sale_document.id,
        amount: amount
      )

      document = Ecr::DocumentRegistrar.refund(form)

      items.each do |item|
        order.refund_order_items.create!(
          ecr_document: document,
          order: order,
          order_item: item[:order_item],
          operator: operator,
          quantity: item[:quantity]
        )

        item[:order_item].refund_to_warehouse! if item[:refund_to_warehouse]
      end

      document
    end
  end

  private

  delegate :vendor, :sale_document, to: :order

  attr_reader :order, :items, :operator

  def validate!(items)
    items.each do |item|
      free_quantity = item[:order_item].quantity - order.refund_order_items.where(order_item: item[:order_item]).sum(:quantity)

      raise Error, "No leftovers to return for order item id: #{item[:order_item].id}" if free_quantity <= 0
      raise Error, "Refund quantity(#{item[:quantity]}) better order_item quantity #{free_quantity}" if item[:quantity] > free_quantity
    end
  end
end
