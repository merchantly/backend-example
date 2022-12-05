class CartService
  MAX_TRY_COUNTS = 3
  include Virtus.model strict: true

  attribute :vendor, Vendor
  attribute :session, ActionDispatch::Request::Session

  delegate :has_good?, :add_good, :remove_good, :update_good, :remove_item, :update_cart_from_params,
           :items, :items_amount, :total_price, :clean!,
           :coupon_code,
           to: :cart!

  def set_package(package_good_global_id)
    cart!.update package_good_global_id: package_good_global_id, package_count: 1
  end

  def set_coupon_code(code)
    cart!.update coupon_code: code
  end

  def coupon
    @coupon ||= vendor.coupons.find_by(code: coupon_code) if coupon_code.present?
  end

  def cart!
    @cart ||= find_cart || create_cart
  end

  def cart
    @cart ||= find_cart
  end

  def cart_for_presentation
    cart || Cart.new(vendor: vendor).freeze
  end

  private

  def find_cart
    return unless session.loaded?

    vendor.carts.find_by(session_id: session.id.to_s)
  end

  def create_cart(try_count = 1)
    raise "Не получилось создать корзину с #{try_count} попытки для сессии #{session.id}" if try_count >= MAX_TRY_COUNTS

    session[:i] = 1 unless session.loaded?

    data = upsert_cart

    data ? Cart.instantiate(data) : (find_cart || create_cart(try_count + 1))
  end

  def upsert_cart
    # Все корзины до фикса с присвоением created_at
    # имеют дату создания - 2017-04-07 09:54:01
    Cart.connection.execute(%{
      insert into carts (session_id, vendor_id, created_at, updated_at)
      values ('#{session.id}', #{vendor.id}, now(), now())
      on conflict (vendor_id, session_id)
      do nothing
      returning *
    }).first
  end
end
