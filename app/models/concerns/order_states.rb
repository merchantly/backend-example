module OrderStates
  extend ActiveSupport::Concern

  included do
    belongs_to :workflow_state, counter_cache: true
    belongs_to :past_workflow_state, class_name: 'WorkflowState'

    scope :in_process, -> { with_finite_state :in_process }
    scope :success,    -> { with_finite_state :success }
    scope :fresh,      -> { with_finite_state [:new] }
    scope :finished,   -> { with_finite_state %i[success failure] }

    scope :by_raw_delivery_state, ->(state) { joins(:order_delivery).where(order_deliveries: { state: state }) }
    scope :by_raw_payment_state,  ->(state) { joins(:order_payment).where(order_payments: { state: state }) }

    scope :with_workflow_state, ->(workflow_state) { where workflow_state_id: workflow_state.id }

    scope :with_finite_state, lambda { |state|
      unless Set.new(Array(state).map(&:to_s)).subset? Set.new(WorkflowState.finite_state.values)
        raise "No such finite_state #{state}"
      end

      joins(:workflow_state).where workflow_states: { finite_state: state }
    }

    scope :by_delivery_state, lambda { |state|
      state = state.to_s
      state = OrderDelivery::STATE_NEW if state.blank?
      if OrderDelivery::STATES.include? state
        by_raw_delivery_state state
      else
        raise "Unknown order delivery state: #{state}"
      end
    }

    scope :by_payment_state, lambda { |state|
      state = state.to_s
      state = OrderPayment::STATE_AWAIT if state.blank?
      if OrderPayment::STATES.include? state
        by_raw_payment_state state
      else
        raise "Unknown order payment state: #{state}"
      end
    }

    scope :by_delivery_type, ->(id) { where delivery_type_id: id }
    scope :by_payment_type,  ->(id) { where payment_type_id: id }
    scope :by_coupon_id,     ->(id) { where coupon_id: id }
    scope :created_at_from,  ->(date) { where 'orders.created_at >= ?', date }
    scope :created_at_to,    ->(date) { where 'orders.created_at <= ?', date }

    before_create :setup_default_workflow_state

    delegate :finite_state, to: :workflow_state
  end

  delegate :delivering?,       to: :order_delivery
  delegate :paid?, :canceled?, to: :order_payment
  delegate :finish?, :in_process?, :success?, :failure?, :new?, to: :workflow_state

  def must_be_paid_online?
    !finish? && !canceled? && !order_payment.paid? && order_payment.pay_online? && delivery_price.is_a?(Money)
  end

  def reset_state!
    ActiveRecord::Base.transaction do
      order_delivery.reset_state!
      order_payment.reset_state!
      if finish?
        archive!
      else
        restore!
      end
    end
  end

  private

  def setup_default_workflow_state
    # TODO кешировать в vendor?
    self.workflow_state ||= vendor.workflow_states.default
  end
end
