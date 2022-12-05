# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :order_item do
    order
    # price { 10.to_money }
    title { 'какой-то товар' }
    good { create :product, :ordering, vendor: order.vendor }
    count { 1 }

    total_sale_amount { Money.zero }

    # order.items.build(
    # good: cart_item.good,
    # price: cart_item.price.exchange_to(order.currency),
    # count: cart_item.count,
    # title: cart_item.title,
    # weight: cart_item.weight,
    # weight_of_price: cart_item.weight_of_price,
    # selling_by_weight: cart_item.selling_by_weight?
    # )
  end
end
