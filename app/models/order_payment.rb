class OrderPayment < ApplicationRecord
  include WorkflowActiverecord
  extend OrderPaymentAgents

  TEMPLATE_CREATED = :created
  TEMPLATE_PAYMENT = :payment
  TEMPLATE_CUSTOM = :custom
  TEMPLATE_CLOUDPAYMENTS = :cloudpayments
  TEMPLATE_ROBOKASSA = :robokassa
  TEMPLATE_TINKOFF = :tinkoff
  TEMPLATE_RBK_MONEY = :rbk_money
  TEMPLATE_SBERBANK = :sberbank
  TEMPLATE_GSDK = :gsdk
  TEMPLATE_GEIDEA_PAYMENT = :geidea_payment
  TEMPLATE_ARSENAL_PAY = :arsenal_pay

  STATE_AWAIT    = 'new'.freeze
  STATE_DIRECT   = 'direct'.freeze
  STATE_FAILED   = 'failed'.freeze
  STATE_PAID     = 'paid'.freeze
  STATE_CANCELED = 'canceled'.freeze

  workflow_column :state

  workflow do
    state STATE_AWAIT do
      event :direct, transitions_to: STATE_DIRECT
      event :pay,    transitions_to: STATE_PAID
      event :fail,   transitions_to: STATE_FAILED
      event :cancel, transitions_to: STATE_CANCELED
    end
    state STATE_DIRECT do
      event :pay,    transitions_to: STATE_PAID
      event :cancel, transitions_to: STATE_CANCELED
    end
    state STATE_FAILED do
      event :pay,    transitions_to: STATE_PAID
      event :fail,   transitions_to: STATE_FAILED
      event :cancel, transitions_to: STATE_CANCELED
    end
    state STATE_PAID do
      event :pay,    transitions_to: STATE_PAID
    end
    state STATE_CANCELED do
      event :cancel, transitions_to: STATE_CANCELED
      event :pay,    transitions_to: STATE_PAID
      event :fail,   transitions_to: STATE_FAILED
    end

    on_transition do |_from, to, _triggering_event, *_event_args|
      if AUTO_ADMIN_COMMENT_STATES.include? to
        order.admin_comments.create! body: I18n.t("order_payment_states_comments.#{to}"), namespace: :admin, is_auto: true
      end
    end
  end

  STATES = workflow_spec.state_names.map(&:to_s)
  AUTO_ADMIN_COMMENT_STATES = STATES - [STATE_AWAIT, STATE_DIRECT]

  scope :success, -> { where state: :paid }

  belongs_to :order
  has_one :payment_type, through: :order
  has_one :vendor, through: :order

  delegate :vendor_id, :total_price, :total_with_delivery_price, :client, to: :order

  before_destroy do
    raise "Oops: cannot be deleted #{id}" if Rails.env.production?
  end

  def self.humanized_name
    I18n.t("agents.payment.#{name.underscore}")
  end

  def humanized_state
    I18n.t("activerecord.attributes.order.payment_states.#{state}")
  end

  def state_updated_at
    return updated_at unless direct? || new?
  end

  def template
    TEMPLATE_CREATED
  end

  def pay_online?
    template != TEMPLATE_CREATED
  end

  def to_s
    title
  end

  def title
    self.class.humanized_name
  end

  def credit!
    return if client.blank?

    client.update! customer_balance: (client.customer_balance - order.total_with_delivery_price)

    update! is_credit: true
  end

  protected

  def pay(response = nil)
    return if paid?

    update! response: response.to_s
    vendor.touch :last_payment_at
    order.on_pay_successful
    NotifyOnlineKassaWorker.perform_async order_id if order.payment_type.enable_online_kassa?

    if is_credit?
      client.update! customer_balance: (client.customer_balance + order.total_with_delivery_price)
    end
  end

  def fail(response = nil)
    update! response: response.to_s
    order.on_pay_failure
  end
end
