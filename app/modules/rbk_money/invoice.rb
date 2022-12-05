class RbkMoney::Invoice
  include Virtus.model

  attribute :id, String, require: true
  attribute :access_token, String, require: true
  attribute :order, Order, require: true

  attribute :description, String, require: true
  attribute :title, String, require: true

  delegate :email, to: :order
end
