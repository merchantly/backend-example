require 'rails_helper'

RSpec.describe OrderCallbacks, type: :model do
  let!(:vendor) { create :vendor, :with_default_order_conditions }
  let!(:payment_type)  { create :vendor_payment, :w1, vendor: vendor }
  let!(:delivery_type) { create :vendor_delivery, :cse, vendor: vendor }
  let!(:order) { create :order, vendor: vendor, payment_type: payment_type, delivery_type: delivery_type }
  let(:failure_state) { vendor.workflow_states.with_finite_state(:failure).first }
  let(:other_state) { vendor.workflow_states.with_finite_state(:in_process).first }

  it 'контролька' do
    expect(failure_state).not_to eq other_state
    expect(failure_state).to be_a WorkflowState
    expect(other_state).to be_a WorkflowState
  end

  context 'changed_workflow' do
    it 'при изменении статуса ловим событие' do
      expect(order).to receive(:changed_workflow)

      order.update! workflow_state_id: vendor.workflow_states.last.id
    end

    it 'в момент создания не вызывается workflow_changed' do
      expect_any_instance_of(OrderNotificationService).not_to receive(:new_order)
      create :order, vendor: vendor, payment_type: payment_type, delivery_type: delivery_type
    end

    it 'когда заказ создается событие workflow_changed не генерится' do
      expect_any_instance_of(OrderNotificationService).not_to receive(:workflow_changed)
      create :order, vendor: vendor, payment_type: payment_type, delivery_type: delivery_type
    end

    it do
      expect_any_instance_of(OrderNotificationService).to receive(:notify_by_template)
      expect(order).to receive(:log!).twice
      order.update! workflow_state: other_state
    end

    it 'если меняем другие поля, то changed_workflow не вызывается' do
      expect(order).not_to receive(:log!)
      expect(order).not_to receive(:changed_workflow)
      order.update! ip: 'some'
    end

    it 'при установке статуса типа failure вызывается событие cancel!' do
      expect(order).to receive(:log!).exactly(3).times
      expect(order).to receive(:cancel!)
      order.update! workflow_state: failure_state
      order.reload
      # expect(order.archived?).to be_truthy
    end
  end

  context 'on_created' do
    it do
      expect_any_instance_of(OrderNotificationService).to receive(:new_order)
      expect { order.on_created }.not_to raise_error
    end
  end
end
