require 'convead_client'

class AnalyticsConvead < BaseAnalytics
  EVENT_UPDATE_INFO = :update_info

  def initialize(vendor:, app_key:, domain:, path:, title:, guest_uid: nil, client: nil)
    @vendor      = vendor
    @app_key     = app_key
    @guest_uid   = guest_uid
    @domain      = domain
    @path        = path
    @title       = title
    @client      = client
  end

  def view_product(product)
    options = {
      product_id: product.id,
      product_name: product.title,
      product_url: product.public_url
    }
    event! EVENT_VIEW_PRODUCT, options
  end

  def add_to_cart(cart_item)
    update_cart cart_item.cart
  end

  def standalone_add_to_cart(cart_item)
    options = {
      qnt: cart_item.quantity,
      product_id: cart_item.product.id,
      product_name: cart_item.product.title,
      product_url: cart_item.product.public_url,
      price: cart_item.price.to_i
    }
    event! EVENT_ADD_TO_CART, options
  end

  def remove_from_cart(cart_item)
    update_cart cart_item.cart
  end

  def standalone_remove_from_cart(cart_item)
    # # Visitor Foo Bar has removed one item of product with ID 1 from cart.
    options = {
      product_id: cart_item.product.id,
      qnt: cart_item.quantity
    }
    event! EVENT_REMOVE_FROM_CART, options
  end

  def update_cart(cart)
    options = {
      items: present_items(cart.try(:items) || [])
    }
    event! EVENT_UPDATE_CART, options
  end

  def purchase(order)
    # Visitor Foo Bar has purchased two products with total revenue 298.0 and order ID 123.
    options = {
      order_id: order.id,
      revenue: order.total_price.to_i,
      items: present_items(order.items)
    }
    event! EVENT_PURCHASE, options
  end

  def subscription_email(email)
    event! EVENT_UPDATE_INFO, email: email
  end

  private

  attr_reader :vendor, :app_key, :domain, :path, :title, :guest_uid, :client

  def present_items(items)
    items.map do |item|
      { product_id: item.product.id, qnt: item.quantity, price: item.price.to_i }
    end
  end

  def user_options
    return {} if client.blank?

    {
      first_name: client.first_name,
      last_name: client.last_name
    }
  end

  def visitor_options
    opts = {
      guest_uid: guest_uid,
      path: path,
      title: title
    }
    opts[:visitor_uid] = client.id if client.present?
    opts
  end

  def event!(event_type, options)
    ConveadWorker.perform_async(vendor.id, app_key, domain, event_type, visitor_options, options, user_options)
  end
end
