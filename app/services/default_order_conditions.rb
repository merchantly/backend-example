# Creates default order conditions for new vendors

class DefaultOrderConditions
  def initialize(vendor)
    @vendor = vendor
  end

  def perform
    vendor.order_conditions.create! conditions_list
  end

  private

  attr_reader :vendor

  def failure_state_id
    vendor.workflow_states.with_finite_state(:failure).first.id
  end

  def success_state_id
    vendor.workflow_states.with_finite_state(:success).first.id
  end

  def in_process_state_id
    vendor.workflow_states.with_finite_state(:in_process).first.id
  end

  def conditions_list
    [
      { action: :reserve, event: :on_create },
      { action: :unreserve, event: :on_workflow_change, enter_workflow_state_id: failure_state_id },
      { action: :unreserve, event: :on_workflow_change, enter_workflow_state_id: in_process_state_id, enter_finite_state: :failure },
      { action: :notification, event: :on_workflow_change, notification_template: 'client:workflow_changed' }
    ]
  end
end
