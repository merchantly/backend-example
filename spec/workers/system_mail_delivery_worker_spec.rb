require 'rails_helper'

describe SystemMailDeliveryWorker do
  subject { described_class.new }

  let(:operator)              { create :operator, :has_vendor }
  let(:vendor)                { operator.vendors.first }
  let(:system_mail_template)  { create :system_mail_template }
  let(:system_mail_delivery)  { create :system_mail_delivery, system_mail_template: system_mail_template }
  let(:system_mail_recipient) { create :system_mail_recipient, delivery: system_mail_delivery, operator: operator, vendor: vendor }

  before do
    ActiveJob::Base.queue_adapter = :inline
  end

  it '#perform' do
    expect_any_instance_of(SystemMailDelivery).to receive(:update_attribute).with(:state, SystemMailDelivery::STATE_PROCESS).and_call_original
    expect_any_instance_of(SystemMailDelivery).to receive(:update_attribute).with(:state, SystemMailDelivery::STATE_DONE).and_call_original
    expect { subject.perform system_mail_delivery.id }.not_to raise_error
  end
end
