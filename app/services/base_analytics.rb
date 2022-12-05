# интерфейс для аналитики

class BaseAnalytics
  EVENT_CREATE_CART = :create_cart
  EVENT_VIEW_PRODUCT = :view_product
  EVENT_ADD_TO_CART = :add_to_cart
  EVENT_REMOVE_FROM_CART = :remove_from_cart
  EVENT_UPDATE_CART = :update_cart
  EVENT_PURCHASE = :purchase

  EVENTS = [
    EVENT_CREATE_CART, EVENT_VIEW_PRODUCT, EVENT_ADD_TO_CART,
    EVENT_UPDATE_CART, EVENT_PURCHASE, EVENT_REMOVE_FROM_CART
  ].freeze

  def visit(path:, resource:); end

  def create_cart(_cart); end

  def view_product(_product); end

  def add_to_cart(_cart_item); end

  def standalone_add_to_cart(_cart_item); end

  def remove_from_cart(_cart_item); end

  def standalone_remove_from_cart(_cart_item); end

  def update_cart(_cart); end

  def purchase(_order); end

  def subscription_email(_email); end
end
