require 'rails_helper'

RSpec.describe OrderCondition, type: :model do
  subject { order_condition }

  let(:order_condition) { create :order_condition }

  it do
    expect(subject).to be_persisted
    expect(subject).to be_valid
  end

  describe 'action notification' do
    let(:order_condition) { build :order_condition, action: :notification, event: :on_create, after_time_minutes: nil, notification_template: nil }

    it 'invalid' do
      expect(subject).to be_invalid
      expect(subject.errors.count).to eq 1
    end
  end

  describe 'action change_status' do
    let(:order_condition) { build :order_condition, action: :change_state, event: :on_create, after_time_minutes: nil, notification_template: nil }

    it 'invalid' do
      expect(subject).to be_invalid
      expect(subject.errors.count).to eq 1
    end
  end

  describe 'action change_status/notification' do
    let(:order_condition) { build :order_condition, action: %i[change_state notification].sample.to_sym, event: :on_create, after_time_minutes: nil, notification_template: '123', to_order_workflow_state_id: 1 }

    it 'valid' do
      expect(subject).to be_valid
    end
  end
end
