class OrderDiscountedPricesBuilder
  include Virtus.model strict: true

  attribute :order, Order

  def perform
    order_prices = build_order_prices
    order_prices = correct_prices order_prices
    validate! order_prices
    order_prices
  end

  private

  def validate!(order_prices)
    return if order.total_with_delivery_price == order_prices.total_price
    # Расхождение в 1 копейку прощаем
    return if (order.total_with_delivery_price.to_f - order_prices.total_price.to_f).abs < 0.02

    raise "При расчете скидки итого не совпало #{order_prices.total_price} <> #{order.total_with_delivery_price}. order_id=#{order.id}"
  end

  # Из-за округления общая сумма может не сойтись,
  # это нормально если в пределах 1 копейки на товар.
  # Добавляем/отнимаем копейку у первых товаров для
  # того чтобы сумма сошлась
  def correct_prices(order_prices)
    diff = (order.total_with_delivery_price - order_prices.total_price).cents
    return order_prices if diff.zero?

    if diff >= 1 && order_prices.items.count <= diff
      raise "too much difference: order_id=#{order.id} diff=#{diff} items_count=#{order_prices.items.count}"
    end

    d = 0.01.to_money(order_prices.items[0].price.currency)
    d = -d if diff.negative?
    diff.abs.times do |i|
      order_prices.items[i].price = order_prices.items[i].price + d
    end

    order_prices
  end

  def build_order_prices
    OrderPrices.new(
      order: order,
      items: build_items,
      delivery: build_delivery,
      package: build_package
    )
  end

  def log(order_prices)
    puts '---'
    order_prices.items.map do |i|
      puts i.total_price
    end
    puts order_prices.delivery.price
  end

  def build_items
    order.items.map { |i| build_order_item_price(i) }.flatten
  end

  def build_order_item_price(order_item)
    if order.discount_price.zero? && order.payment_discount_price.zero?
      OrderItemPrice.new(
        price: item_price(order_item),
        title: order_item.title,
        tax_type: order_item.tax_type,
        quantity: order_item.quantity,
        good: order_item.good,
        vat: order_item.cached_vat,
        id: order_item.id,
        vat_amount: order_item.vat_amount,
        original_price: order_item.price
      )
    else
      # Чтобы скидка равномерно распределилась между товарами
      (1..order_item.quantity).map do
        OrderItemPrice.new(
          price: item_price(order_item),
          title: order_item.title,
          tax_type: order_item.tax_type,
          quantity: 1,
          good: order_item.good,
          vat: order_item.cached_vat,
          id: order_item.id,
          vat_amount: order_item.vat_amount,
          original_price: order_item.price
        )
      end
    end
  end

  def item_price(order_item)
    return 0.to_money(order.currency) if order.total_price.zero? # Ситуация когда скидка полностью покрывает заказ

    item_total_price = order_item.price * order_item.quantity

    discount_price = order.payment_discount_price + order.discount_price

    item_discount_price = (item_total_price / order.products_price) * discount_price

    (item_total_price - item_discount_price) / order_item.quantity
  end

  def build_package
    OrderItemPrice.new(
      title: order.package_good.try(:title),
      price: package_price,
      tax_type: order.package_good.try(:tax_type),
      quantity: 1,
      good: order.package_good
    )
  end

  def package_price
    # Ситуация когда скидка полностью покрывает заказ
    order.total_price.zero? ? 0.to_money(order.currency) : order.package_price
  end

  def build_delivery
    OrderItemPrice.new(
      title: order.delivery_type.title,
      price: delivery_price,
      tax_type: order.delivery_type.tax_type,
      quantity: 1
    )
  end

  def delivery_price
    order.delivery_price.nil? ? 0.to_money(order.currency) : order.delivery_price
  end
end
