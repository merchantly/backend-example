class BaseFormOptions
  include Rails.application.routes.url_helpers

  attr_accessor :order

  delegate :vendor, to: :order

  def self.generate(order, force_delivery = false)
    new(order, force_delivery).generate
  end

  def initialize(order, force_delivery = false)
    raise 'Объект не является заказом' unless order.is_a? Order

    @order = order
    @force_delivery = force_delivery
  end

  def generate
    @list = []
    fill_fields
    @list
  end

  private

  def add(key, value)
    @list.push [key, value]
  end
end
