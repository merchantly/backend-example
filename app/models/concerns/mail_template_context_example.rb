module MailTemplateContextExample
  CLIENT_ONLY_KEYS = %w[client_category_changed].freeze
  ORDER_ITEM_ONLY_KEYS = %w[coupon].freeze

  def context_example
    MailContext.new order: example_order, client: example_client, order_item: example_order_item, template: self
  end

  def context_example_to_validate
    context_example
  end

  def example_subject
    context_example.subject
  end

  def example_from
    context_example.from
  end

  def example_to
    context_example.to
  end

  def example_content_html
    to_html context_example.to_liquid
  end

  def example_content_text
    to_text context_example.to_liquid
  end

  def example_content_sms
    to_sms context_example.to_liquid
  end

  def order_id
    example_order.try(:id)
  end

  def example_order=(order)
    @example_order = order
  end

  private

  def example_client
    return if ORDER_ITEM_ONLY_KEYS.include?(key)

    Client.new(
      id: -1,
      name: I18n.t('mail_template_example.client.name'),
      emails: [ClientEmail.new(email: I18n.t('mail_template_example.client.email'))],
      orders_count: 123,
      address: I18n.t('mail_template_example.client.address'),
      total_orders_price: Money.new(250_000, example_vendor.default_currency),
      occupation_name: I18n.t('mail_template_example.client.occupation_name'),
      client_category_id: 123,
      vendor: example_vendor
    )
  end

  def example_order
    return if CLIENT_ONLY_KEYS.include?(key) || ORDER_ITEM_ONLY_KEYS.include?(key)
    return @example_order if @example_order.present?

    order = Order.new(
      id: -1,
      address: I18n.t('mail_template_example.order.address'),
      city_title: I18n.t('mail_template_example.order.city_title'),
      name: I18n.t('mail_template_example.order.name'),
      email: I18n.t('mail_template_example.order.email'),
      phone: I18n.t('mail_template_example.order.phone'),
      total_price: Money.new(300_000, example_vendor.default_currency),
      delivery_price: Money.new(50_000, example_vendor.default_currency),
      total_with_delivery_price: Money.new(350_000, example_vendor.default_currency),
      total_vat: Money.new(3_000, example_vendor.default_currency),
      payment_type: example_payment_type,
      delivery_type: example_delivery_type,
      vendor: example_vendor,
      workflow_state: example_workflow_state,
      order_delivery: example_delivery_dates,
      order_payment: example_order_payment
    )
    order.items = example_order_items(order)
    order
  end

  def example_delivery_dates
    OrderDelivery.new(
      date_from: Time.zone.now,
      date_till: 3.days.from_now
    )
  end

  def example_order_item
    OrderItem.new(
      id: -1,
      title: 'Купон',
      price: Money.new(50_000, example_vendor.default_currency),
      count: 1,
      good: Product.new(title: I18n.t('mail_template_example.product.name'), article: I18n.t('mail_template_example.product.article', num: 1), vendor: example_vendor),
      order: Order.new(id: -1, address: I18n.t('mail_template_example.order.address'), vendor: example_vendor, name: I18n.t('mail_template_example.order.name'))
    )
  end

  def example_workflow_state
    example_vendor.workflow_states.build name: I18n.t('mail_template_example.worflow_state.name')
  end

  def example_order_items(order)
    items = []

    good = Product.new title: I18n.t('mail_template_example.product.name'), article: I18n.t('mail_template_example.product.article', num: 1), vendor: vendor
    good.price = Money.new(50_000, example_vendor.default_currency)
    items << OrderItem.new(id: -1, title: good.title, price: Money.new(50_000, example_vendor.default_currency), count: 2, good: good, order: order)
    good = Product.new title: I18n.t('mail_template_example.product.name'), article: I18n.t('mail_template_example.product.article', num: 2), vendor: vendor
    good.price = Money.new(250_000, example_vendor.default_currency)
    good.sale_price = Money.new(200_000, example_vendor.default_currency)
    items << OrderItem.new(id: -1, title: good.title, price: Money.new(200_000, example_vendor.default_currency), count: 1, good: good, order: order)
    items
  end

  def example_payment_type
    example_vendor.vendor_payments.build payment_agent_type: OrderPaymentW1.name, title: 'PayPal', description: I18n.t('mail_template_example.payment_type.description')
  end

  def example_delivery_type
    example_vendor.vendor_deliveries.build delivery_agent_type: OrderDeliveryRedexpress.name, title: 'DHL', description: I18n.t('mail_template_example.delivery_type.description')
  end

  def example_order_payment
    OrderPaymentTinkoff.new payment_type: example_payment_type
  end

  def example_vendor
    @example_vendor ||= vendor.presence || Thread.current[:vendor] || Vendor.new(title: I18n.t('mail_template_example.vendor.name'))
  end

  def context_type
    :order
  end
end
