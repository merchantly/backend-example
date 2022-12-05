class ClientsSpreadsheet < AbstractBaseSpreadsheet
  FIELDS = %w[id name phones emails orders_count total_orders_price currency orders_numbers first_order_created_at last_order_created_at products_count products_titles products_articles created_at recency rfm].freeze

  def initialize(collection, vendor:)
    @vendor = vendor
    super collection
  end

  private

  attr_reader :vendor

  def encoding
    'cp1251'
  end

  def header_row
    FIELDS.map { |f| Client.human_attribute_name f }
  end

  def row(client)
    [
      client.id,
      client.name,
      client.phones_array.join(', '),
      client.emails_array.join(', '),
      client.orders_count,
      client.total_orders_price,
      client.total_orders_price.currency.to_s,
      orders_numbers(client),
      time_format(client.first_order_created_at),
      time_format(client.last_order_created_at),
      products_count(client),
      products_titles(client),
      products_articles(client),
      time_format(client.created_at),
      client.recency,
      rfm(client),
    ]
  end

  def rfm(client)
    "#{client.rfm} (#{client.rfm.segment})"
  end

  def time_format(time)
    return if time.blank?

    I18n.l(time, format: :amo_csv)
  end

  def orders_numbers(client)
    client.orders.map(&:title).join(', ')
  end

  def products_count(client)
    client.order_items.sum(&:quantity)
  end

  def products_articles(client)
    client.order_items.map(&:product_article).join(', ')
  end

  def products_titles(client)
    client.order_items.map(&:good).compact.map(&:long_title).join(', ')
  end
end
