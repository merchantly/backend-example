class OrderOperatorFilter < ApplicationRecord
  include Authority::Abilities
  include RankedModel
  include ColorHex

  EXCLUDE_PARAMS = %i[action controller page query per_page].freeze
  DEFAULT_COLOR_HEX = '#808080'.freeze

  ranks :row_order, with_same: :vendor_id

  belongs_to :vendor
  belongs_to :coupon
  belongs_to :workflow_state
  belongs_to :delivery_type, class_name: 'VendorDelivery'
  belongs_to :payment_type, class_name: 'VendorPayment'

  validates :name, :color_hex, presence: true

  translates :name

  scope :ordered, -> { order :row_order }

  before_validation do
    set_defaults
  end

  def set_defaults
    if color_hex.blank?
      self.color_hex = workflow_state.try(:color_hex) || DEFAULT_COLOR_HEX
    end
  end

  def params
    {
      coupon_id: coupon_id,
      workflow_state_id: workflow_state_id,
      delivery_type_id: delivery_type_id,
      payment_type_id: payment_type_id,
      has_reserved_items: has_reserved_items,
      delivery_state: delivery_state,
      payment_state: payment_state
    }.select { |_k, v| v.present? }
  end

  # повторяем интерфейс VendorOrdersFilter
  def query
    nil
  end

  def finite_state
    nil
  end

  # вместо этого будет фильтровать по coupon_id
  def coupon_code
    nil
  end

  def client
    nil
  end

  def created_at_from
    nil
  end

  def created_at_to
    nil
  end

  def source
    nil
  end

  def refund
    nil
  end

  def tid
    nil
  end

  def transaction_id
    nil
  end

  def payment_key
    nil
  end

  def equal_params?(front_orders_filter_params)
    front_orders_filter_params.reject { |k, v| EXCLUDE_PARAMS.include?(k.to_sym) || v.blank? }.sort == params.to_h { |k, v| [k, v] }.sort
  end

  def orders
    VendorOrdersQuery.new(vendor: vendor, filter: self).base_scope
  end
end
