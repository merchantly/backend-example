class AnalyticsVendor < BaseAnalytics
  # cookies ActionDispatch::Cookies::CookieJar
  # request ActionDispatch::Request
  # session ActionDispatch::Request::Session

  def initialize(vendor:, request:, session:, cookies:, datetime: Time.zone.now)
    @vendor   = vendor
    @cookies  = cookies
    @datetime = datetime
    @request  = request
    @session  = session
    @datetime = datetime
  end

  def visit_sources_ids
    @visit_sources_ids ||= find_visit_sources_ids
  end

  def visit_id
    @visit_id ||= find_visit_id
  end

  def visit(path:, resource:)
    product_id = resource.main.id if resource.is_a? Product
    VendorAnalyticsVisitorEvent.delay(queue: :low).create(
      vendor_id: vendor.id,
      session_id: session_id,
      visit_id: visit_id,
      path: path,
      resource_id: resource.try(:id),
      resource_type: resource.present? ? resource.class.name : nil,
      product_id: product_id,
      event: :visit
    )
  end

  def view_product(product)
    VendorProductAnalyticsDay.delay(queue: :low).upsert vendor_id: vendor.id, date: date, product_id: product.main.id, views_count: 1
    VendorAnalyticsDay.delay(queue: :low).upsert vendor_id: vendor.id, date: date, product_views_count: 1
    VendorAnalyticsSessionProduct.delay(queue: :low).upsert(
      vendor_id: vendor.id,
      datetime: datetime,
      session_id: session_id,
      product_id: product.main.id,
      views_count: 1
    )
  end

  def add_to_cart(cart_item)
    VendorProductAnalyticsDay.delay(queue: :low).upsert(
      vendor_id: vendor.id,
      date: date,
      product_id: cart_item.product.main.id,
      carts_count: 1
    )
    VendorAnalyticsSessionProduct.delay(queue: :low).upsert(
      vendor_id: vendor.id,
      datetime: datetime,
      session_id: session_id,
      product_id: cart_item.product.main.id,
      carts_count: 1
    )
  end

  def purchase(order)
    order.items.each do |item|
      VendorProductAnalyticsDay.delay(queue: :low).upsert(
        vendor_id: vendor.id,
        date: date,
        product_id: item.product.main.id,
        orders_count: 1
      )
      VendorAnalyticsSessionProduct.delay(queue: :low).upsert(
        vendor_id: vendor.id,
        datetime: datetime,
        session_id: session_id,
        product_id: item.product.main.id,
        orders_count: 1
      )
    end
    VendorAnalyticsDay.delay(queue: :low).upsert vendor_id: vendor.id, date: date, orders_count: 1
  end

  def create_cart(_cart)
    VendorAnalyticsDay.delay(queue: :low).upsert vendor_id: vendor.id, date: date, carts_count: 1
  end

  private

  attr_reader :vendor, :datetime, :request, :cookies, :session

  delegate :path, :user_agent, :remote_ip, :referer, to: :request

  def find_visit_sources_ids
    referer = request.referer.to_s.squish.chomp.slice(0, 2083)
    utm = UtmEntity.build_from_params request.query_parameters

    sources_ids = []

    sources_ids << VendorAnalyticsSourceReferer.safe_create(vendor_id: vendor.id, referer: referer, created_at: datetime) if referer.present?
    sources_ids << VendorAnalyticsSourceUtm.safe_create(vendor_id: vendor.id, utm: utm, created_at: datetime) if utm.present?
    sources_ids
  rescue StandardError => e
    Bugsnag.notify e
    []
  end

  def date
    datetime.to_date
  end

  def find_visit_id
    cookies.signed[:visit_id] || create_visit_id
  end

  def create_visit_id
    visit_id = SecureRandom.hex(16)

    VendorAnalyticsVisit.safe_create(
      id: visit_id,
      vendor_id: vendor.id,
      session_id: session_id,
      user_agent: user_agent,
      referer: referer,
      remote_ip: remote_ip,
      params: request.query_parameters,
      created_at: datetime,
      sources_ids: visit_sources_ids
    )

    visit_sources_ids.each do |id|
      VendorAnalyticsVisitToSource.safe_create(
        vendor_id: vendor.id,
        session_id: session_id,
        visit_id: visit_id,
        created_at: datetime,
        source_id: id
      )
    end

    create_visitor visit_id

    cookies.signed[:visit_id] = visit_id
  end

  def session_id
    session[:i] = true unless session.loaded?
    session.try(:id).try(:to_s)
  end

  def create_visitor(first_visit_id)
    return if VendorAnalyticsVisitor.exists?(vendor_id: vendor.id, session_id: session_id)

    VendorAnalyticsVisitor.safe_create(
      vendor_id: vendor.id,
      session_id: session_id,
      first_visit_id: first_visit_id,
      created_at: datetime
    )
  end
end
