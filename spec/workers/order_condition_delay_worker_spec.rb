require 'rails_helper'

describe OrderConditionDelayWorker do
  subject do
    described_class.new
  end

  let(:vendor) { create :vendor }
  let(:order) { create :order, vendor: vendor }

  describe do
    let(:order_condition) { create :order_condition, vendor: vendor, action: 'delivery', event: 'on_create' }

    it do
      expect_any_instance_of(OrderCondition).to receive(:do_action!).with(order)
      subject.perform order_condition.id, order.id
    end
  end
end
