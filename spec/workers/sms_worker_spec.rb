require 'rails_helper'

describe SmsWorker do
  let(:message) { ' some text ' }
  let(:sms_count) { 10 }
  let(:vendor) { create :vendor, sms_count: sms_count }

  before do
    allow_any_instance_of(described_class).to receive(:notify_sms_money_limit_reached)
  end

  describe 'test phone' do
    subject do
      described_class.new.perform [Settings.test.phone], message, vendor.id
    end

    it do
      expect_any_instance_of(SmsDelivery::Sender).not_to receive :call
      subject
    end
  end

  describe 'pay sms' do
    let(:from_amount) { -to_amount }

    context 'array phones' do
      subject do
        described_class.new.perform phones, message, vendor.id
      end

      let(:to_amount) { Money.new(4_00, TariffBase::DEFAULT_CURRENCY) }
      let(:phones) { ['+7123213', '+12312321'] }

      it do
        expect(subject).to be_a VendorSmsLogEntity
        expect(vendor.reload.sms_count).to eq sms_count - 2
      end
    end

    context 'string phone' do
      subject do
        described_class.new.perform phone, message, vendor.id
      end

      let(:to_amount) { Money.new(2_00, TariffBase::DEFAULT_CURRENCY) }
      let(:phone) { '+7123213' }

      it do
        expect(subject).to be_a VendorSmsLogEntity
        expect(vendor.reload.sms_count).to eq sms_count - 1
      end
    end
  end

  describe 'отправляем две одинаковых смс' do
    subject do
      described_class.new.perform phone, message, vendor.id
    end

    let(:phone) { '+7123213' }

    before do
      subject
      subject
    end

    it 'вторая не должна отправиться' do
      expect(VendorSmsLogEntity.count).to eq 1
      expect(vendor.reload.sms_count).to eq sms_count - 1
    end
  end
end
