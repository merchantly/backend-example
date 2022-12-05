class Analytics
  delegate :visit_id, :visit_sources_ids, to: :analytics_vendor

  # session is a ActionDispatch::Request::Session
  def initialize(vendor:, client:, request:, cookies:, title: nil, session: nil, datetime: Time.zone.now)
    @title      = title
    @vendor     = vendor
    @client     = client
    @session    = session
    @request    = request
    @cookies    = cookies
    @datetime   = datetime
  end

  def log_visit(resource:)
    clients.each do |c|
      c.visit path: path, resource: resource
    end
  end

  def view_product(product)
    clients.each do |c|
      c.view_product product
    end
  end

  def add_to_cart(cart_item)
    clients.each do |c|
      c.add_to_cart cart_item

      # Если это первый добавленный товар то считаем что корзина создана
      c.create_cart(cart_item.cart) if cart_item.cart.items_count.zero? || (cart_item.cart.items.one? && cart_item.cart.items.include?(cart_item))
    end
  end

  def remove_from_cart(cart_item)
    clients.each do |c|
      c.remove_from_cart cart_item
    end
  end

  def update_cart(cart)
    clients.each do |c|
      c.update_cart cart
    end
  end

  def purchase(order)
    clients.each do |c|
      c.purchase order
    end
  end

  def subscription_email(email)
    clients.each do |c|
      c.subscription_email email
    end
  end

  private

  attr_reader :vendor, :client, :title, :session, :request, :datetime, :cookies

  delegate :path, :user_agent, :remote_ip, :referer, to: :request

  def clients
    @clients ||= build_clients
  end

  def build_clients
    list = []

    if convead_guest_uid.present? && vendor.convead_app_key.present?
      list << AnalyticsConvead.new(
        vendor: vendor,
        app_key: vendor.convead_app_key,
        guest_uid: convead_guest_uid,
        path: path,
        client: client,
        domain: vendor.host,
        title: title
      )
    end

    list << analytics_vendor if Settings.save_analytics

    list
  end

  def analytics_vendor
    @analytics_vendor ||= AnalyticsVendor.new(vendor: vendor, request: request, session: session, cookies: cookies, datetime: datetime)
  end

  def convead_guest_uid
    cookies['convead_guest_uid']
  end
end
