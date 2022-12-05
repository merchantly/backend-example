# Create order by operator
class OrderCreator
  NotActiveDigitalKeys = Class.new StandardError

  # эти ошибки обрабатываются выше, не нужно их слать в bugsnag
  BUGSNAG_IGNORE_ERRORS = [
    ActiveRecord::RecordInvalid,
    CartEmptyError,
    CartHasUnorderableItemsError,
    InvalidFormError
  ].freeze

  attr_reader :order_form, :order

  delegate :cart, :custom_amounts, :allowance, to: :order_form

  def initialize(order_form, session_id: nil, visit_id: nil, visit_sources_ids: [], current_client: nil)
    @order_form = order_form
    @session_id = session_id
    @visit_sources_ids = visit_sources_ids
    @visit_id = visit_id
    @current_client = current_client
  end

  def perform
    raise GeideaSellingError unless order_form.vendor.can_selling?
    raise CartEmptyError if items_count.zero?
    raise CartHasUnorderableItemsError.new(order_form) if has_unorderable_items?
    raise InvalidFormError.new(order_form) unless order_form.valid?
    raise UnavailableGeideaPayment if order_form.payment_type.geidea_payment? && !geidea_payment_available?

    @exception = nil
    with_lock do
        # queries count: 1
        ActiveRecord::Base.log_queries_count 'order_build' do
          @order = order_form
            .vendor
            .orders
            .build(
              order_form.order_attributes.merge(items_count: items_count)
            )

          @order.visit_id = visit_id
          @order.session_id = session_id
          @order.visit_sources_ids = visit_sources_ids
        end

        if @order.client_id.nil? && client_data_present?
          ActiveRecord::Base.log_queries_count 'order attach_client' do
            @order.client = attach_client
          end
        end

        # queries count: 5 (запускал для 3 item-ов)
        ActiveRecord::Base.log_queries_count 'build_order_items' do
          # TODO build insert https://github.com/jamis/bulk_insert
          build_order_items
        end

        # queries count: 0 (без купоов запускал)
        ActiveRecord::Base.log_queries_count 'use_coupon' do
          use_coupon
        end

        ActiveRecord::Base.log_queries_count 'build_digital_keys' do
          build_digital_keys
        end

        ActiveRecord::Base.log_queries_count 'order.save!' do
          order.save!
        end

        # queries count: 2
        # все праввильно: delete from cart_items + update carts set items_count=0
        if cart.present?
          ActiveRecord::Base.log_queries_count 'cart.clean!' do
            cart.clean!
          end
        end
        # если заказ имеет 0 руб, то сразу помечаем как оплаченный
        order.order_payment.pay! if order.free? && !order.custom_delivery_price? && !order.paid?
        order.order_payment.credit! if order.client.present? && order_form.is_credit
    rescue StandardError => e
        @exception = e
        Bugsnag.notify e, metaData: { cart_id: cart.try(:id), custom_amounts: custom_amounts } unless BUGSNAG_IGNORE_ERRORS.include?(e.class) || e.is_a?(Coupon::Error)
        raise @exception
    end

    raise @exception if @exception.present?

    ActiveRecord::Base.log_queries_count 'parse delivery address' do
      parse_delivery_address_if_needed
    end

    # Колбек вызываем послетранзакции, чтобы при отправке письем заказ уже был
    OrderCreatedWorker.perform_async order.id

    order
  end

  def attach_client
    current_client ||
      order_form.vendor.clients.by_phone_or_email(order_form.phone, order_form.email).first ||
      order_form.vendor.clients.create!(
        address: order_form.address,
        vendor_id: order_form.vendor.id,
        name: order_form.full_name,
        phones_attributes: order_form.phone.present? ? { 0 => { phone: order_form.phone } } : {},
        emails_attributes: order_form.email.present? ? { 0 => { email: order_form.email } } : {}
      )
  end

  def order_payments_fields
    form = order.order_payment.payments_fields
    W1.logger.info vendor_id: order.vendor_id, order_id: order.id, message: 'Payment form', form: form
    form
  end

  def order_payment_url
    order.order_payment.payment_url
  end

  private

  attr_reader :visit_id, :session_id, :visit_sources_ids, :current_client

  def geidea_payment_available?
    GeideaPaymentConfig::ErrorChecker.merchant_id(order_form.payment_type.geidea_payment_merchant_id)
    GeideaPaymentConfig::ErrorChecker.currency(order_form.payment_type.geidea_payment_merchant_id, order_form.currency_iso_code)

    true
  rescue GeideaPaymentConfig::MerchantIdInvalidError, GeideaPaymentConfig::CurrencyInvalidError
    false
  end

  def client_data_present?
    order_form.full_name.present? && (order_form.phone.present? || order_form.email.present?)
  end

  def with_lock(&block)
    if cart.present?
      cart.with_lock(&block)
    else
      yield
    end
  end

  def items_count
    count = 0
    count += custom_amounts.count if custom_amounts.present?
    count += cart.items.count if cart.present?
    count
  end

  def has_unorderable_items?
    has_unorderable_items_to_custom_amounts? || has_unorderable_items_to_cart?
  end

  def has_unorderable_items_to_custom_amounts?
    return false if custom_amounts.blank?

    custom_amounts.map(&:invalid?).reduce :|
  end

  def has_unorderable_items_to_cart?
    return false if cart.blank?

    cart.has_unorderable_items?
  end

  def use_coupon
    coupon = find_coupon_by_code || create_coupon_by_allowance

    return if coupon.blank?

    coupon.call!(
      items_count: cart.items.sum(:count),
      is_first_client_order: (order.client.present? ? order.client.orders_count.zero? : true),
      is_address_used: order.address.present? && order.vendor.orders.by_address(order.address).exists?,
      total_price: cart.products_with_package_price
    )

    order.coupon = coupon
  end

  def create_coupon_by_allowance
    return if allowance.blank?

    Allowance.create!(allowance)
  end

  def find_coupon_by_code
    coupon_code = order_form.coupon_code.presence || cart.try(:coupon_code)

    return if coupon_code.blank?

    order.vendor.coupons.by_code(coupon_code) || raise(Coupon::NotFound, coupon_code)
  end

  def parse_delivery_address_if_needed
    return if !order.vendor.clean_order_address? || !order.require_address?

    parse_delivery_address
  rescue DaDataError::UndeterminedAddress => e
    Bugsnag.notify e, metaData: { order_id: order.id }
  end

  def parse_delivery_address
    address_service = DaData::Address.new(raw_address: order.address)
    # TODO аааа! Тут же делается HTTP запрос?? И это во время создания заказа?
    DaData::OrderDeliveryCleanAddress.new(order: order, address_service: address_service).call
  end

  def build_order_items
    build_order_items_from_custom_amounts if custom_amounts.present?
    build_order_items_from_cart if cart.present?
  end

  def build_order_items_from_cart
    cart.items.includes(:good).find_each do |cart_item|
      if cart_item.good.has_digital_keys?
        # 1 ключ - 1 order_item
        cart_item.count.times { build_order_item(cart_item, 1) }
      else
        build_order_item(cart_item, cart_item.count)
      end
    end
  end

  def build_order_items_from_custom_amounts
    custom_amounts.map do |custom_amount|
      order.items.build(
        vendor_id: order_form.vendor.id,
        price: Money.new(custom_amount.price, order.currency),
        total_sale_amount: order_form.vendor.zero_money,
        count: 1,
        title: (custom_amount.title || I18n.t('titles.fallback_good.default')),
        purchase_price: custom_amount.purchase_price,
        cached_vat: (custom_amount.tax || order_form.vendor.default_product_vat_group.try(:vat))
      )
    end
  end

  def build_order_item(cart_item, count)
    order.items.build(
      vendor_id: order_form.vendor.id,
      good: cart_item.good,
      price: cart_item.price.exchange_to(order.currency),
      total_sale_amount: cart_item.total_sale_amount,
      count: count,
      title: cart_item.title,
      weight: cart_item.weight,
      weight_of_price: cart_item.weight_of_price,
      selling_by_weight: cart_item.selling_by_weight?
    )
  end

  def build_digital_keys
    order.items.each do |order_item|
      build_digital_key(order_item)
    end
  end

  def build_digital_key(order_item)
    return if order_item.product.blank?

    product = order_item.product

    return unless product.has_digital_keys?

    raise NotActiveDigitalKeys if product.active_digital_keys_count.zero?

    order_item.digital_key = product.active_digital_keys.first
  end
end
