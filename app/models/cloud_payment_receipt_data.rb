class CloudPaymentReceiptData
  include Virtus.model

  # 1 — FullPrepayment, Предоплата 100%
  INVOICE_PAYMENT_METHOD = 1
  ORDER_PAYMENT_METHOD = 1

  INVOICE_PAYMENT_OBJECT = 4 # 4 - Service, Услуга
  ORDER_PAYMENT_OBJECT = 1 # 1 - Commodity, Товар

  TAX_TYPES = {
    tax_ru_1: nil,
    tax_ru_2: 0,
    tax_ru_3: 10,
    tax_ru_4: 18,
    tax_ru_5: 110,
    tax_ru_6: 118,
    tax_ru_7: 20,
    tax_ru_8: 120
  }.freeze

  attribute :invoice, OpenbillInvoice
  attribute :order, Order

  def data
    receipt = {
      Items: items.compact,
      taxationSystem: taxation_system
    }

    if client.present?
      receipt[:email] = client.email.to_s if client.email.present?
      receipt[:phone] = client.phone.to_s if client.phone.present?
    end

    receipt
  end

  private

  def items
    return invoice_items if invoice.present?
    return order_items if order.present?
  end

  def order_items
    order.order_prices.items.map do |item|
      {
        label: item.title,            # наименование товара
        price: item.price.to_f,       # цена
        quantity: item.quantity.to_f, # количество
        amount: item.total_price.to_f, # сумма
        vat: tax(item.tax_type), # ставка НДС, если не указано то не облагается
        method: ORDER_PAYMENT_METHOD,
        object: ORDER_PAYMENT_OBJECT
      }
    end + [delivery_item, package_item]
  end

  def delivery_item
    return if order.delivery_price.zero? || order.delivery_price.nil?

    delivery = order.order_prices.delivery

    {
      label: delivery.title,            # наименование товара
      price: delivery.price.to_f,       # цена
      quantity: delivery.quantity.to_f, # количество
      amount: delivery.total_price.to_f, # сумма
      vat: tax(delivery.tax_type), # ставка НДС, если не указано то не облагается
      method: ORDER_PAYMENT_METHOD,
      object: 4 # Услуга
    }
  end

  def package_item
    return if order.package_price.zero?

    package = order.order_prices.package

    {
      label: package.title,            # наименование товара
      price: package.price.to_f,       # цена
      quantity: package.quantity.to_f, # количество
      amount: package.total_price.to_f, # сумма
      vat: tax(package.tax_type), # ставка НДС, если не указано то не облагается
      method: ORDER_PAYMENT_METHOD,
      object: ORDER_PAYMENT_OBJECT
    }
  end

  def invoice_items
    [
      {
        label: invoice.title,        # наименование товара
        price: invoice.amount.to_f,  # цена
        quantity: 1.00,              # количество
        amount: invoice.amount.to_f, # сумма
        # vat": 0                    # ставка НДС, если не указано то не облагается
        method: INVOICE_PAYMENT_METHOD,
        object: INVOICE_PAYMENT_OBJECT
      },
    ]
  end

  def client
    if invoice.present?
      owner = invoice.vendor.owners.first
      return owner if owner.present?

      Bugsnag.notify "У вендора #{invoice.vendor.host} нет owners", metaData: { vendor_id: invoice.vendor.id }
      return
    end

    return order.client if order.present?
  end

  # Варианты системы налогообложения:
  # 0 — Общая система налогообложения
  # 1 — Упрощенная система налогообложения (Доход)
  # 2 — Упрощенная система налогообложения (Доход минус Расход)
  # 3 — Единый налог на вмененный доход
  # 4 — Единый сельскохозяйственный налог
  # 5 — Патентная система налогообложения
  def taxation_system
    return Settings.cloud_payments_receipt_data.taxation_system if invoice.present?
    return order.vendor.tax_mode if order.present?
  end

  def tax(tax_type)
    return if tax_type.nil?

    current_tax = TAX_TYPES[tax_type.to_sym]

    raise("Unknown tax_type #{tax_type} vendor #{order.vendor.id}") if current_tax.nil? && tax_type.to_sym != :tax_ru_1
  end
end
