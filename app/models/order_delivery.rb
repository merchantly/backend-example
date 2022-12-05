class OrderDelivery < ApplicationRecord
  include WorkflowActiverecord
  extend OrderDeliveryAgents

  STATE_NEW        = 'new'.freeze
  STATE_NOT_NEEDED = 'not_needed'.freeze
  STATE_DELIVERY   = 'delivery'.freeze
  STATE_DONE       = 'done'.freeze
  STATE_CANCELED   = 'canceled'.freeze

  workflow_column :state

  workflow do
    state STATE_NEW do
      event :not_needed, transitions_to: STATE_NOT_NEEDED
      event :delivery,   transitions_to: STATE_DELIVERY
      event :done,       transitions_to: STATE_DONE
      event :cancel,     transitions_to: STATE_CANCELED
    end
    state STATE_DELIVERY do
      event :delivery,   transitions_to: STATE_DELIVERY
      event :cancel,     transitions_to: STATE_CANCELED
      event :done,       transitions_to: STATE_DONE
    end
    state STATE_NOT_NEEDED do
      event :delivery,   transitions_to: STATE_NOT_NEEDED
      event :cancel,     transitions_to: STATE_CANCELED
      event :done,       transitions_to: STATE_DONE
    end
    state STATE_DONE do
      event :done, transitions_to: STATE_DONE
    end
    state STATE_CANCELED do
      event :cancel,     transitions_to: STATE_CANCELED
      event :delivery,   transitions_to: STATE_DELIVERY
    end

    on_transition do |_from, to, _triggering_event, *_event_args|
      if AUTO_ADMIN_COMMENT_STATES.include? to
        order.admin_comments.create! body: I18n.t("order_delivery_states_comments.#{to}"), namespace: :admin, is_auto: true
      end
    end
  end

  STATES = workflow_spec.state_names.map(&:to_s)
  AUTO_ADMIN_COMMENT_STATES = STATES - [STATE_NEW, STATE_NOT_NEEDED]

  belongs_to :order
  has_one :delivery_type, through: :order
  has_one :vendor, through: :order

  scope :in_progress, -> { where state: STATE_DELIVERY }
  scope :with_tracking_id, -> { where.not(external_id: nil) }

  def need_delivery?
    [STATE_NEW, STATE_CANCELED].include?(state) && !selfdelivery?
  end

  def delivering?
    delivery?
  end

  def is_digital_only?
    false
  end

  def selfdelivery?
    false
  end

  def to_s
    title
  end

  def title
    self.class.humanized_name
  end

  def self.humanized_name
    I18n.t("agents.delivery.#{name.underscore}")
  end

  def tracking_url
    # 'http://www.trackchecker.ru/tracking/?1234'
  end

  def tracking_id
    external_id
  end

  def param_key
    :order_delivery
  end

  def reset_state!
    not_needed! if is_a?(OrderDeliveryPickup) && !not_needed?
  end

  def support_agents?
    false
  end

  def start_delivery_by_agent!(_now = false)
    # TODO уведомляем агента о начале доставки
  end

  def can_start_delivery?
    support_agents?
  end

  protected

  def done
    order.issue_from_warehouse! if IntegrationModules.enable?(:ecr)
  end

  def cancel
    # TODO: redexpress cancel delivery!
  end
end
