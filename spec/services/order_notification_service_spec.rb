require 'rails_helper'

describe OrderNotificationService do
  include CurrentVendor

  subject { described_class.new order }

  let(:order)  { create :order }
  let(:vendor) { order.vendor }
  let(:mailer) { double deliver: true }
  let(:tariff) { create :tariff }

  before :all do
    Sidekiq::Testing.fake!
  end

  before do
    ActiveJob::Base.queue_adapter = :sidekiq
    set_current_vendor vendor
    vendor.update_attribute :tariff, tariff
  end

  describe '#new_order' do
    context 'доставка самовывоз' do
      let(:order) { create :order, :delivery_pickup }

      it do
        expect(subject).to receive(:send_sms).twice
        expect(subject).to receive(:send_email_to_client).with(:new_order, nil)
        expect(subject).to receive(:send_email_to_vendor).with(:new_order, nil)
        subject.new_order
      end
    end

    context 'доставка курьером' do
      let(:order) { create :order, :delivery_cse }

      it do
        expect(subject).to receive(:send_sms).twice
        expect(subject).to receive(:send_email_to_client).with(:new_order, nil)
        expect(subject).to receive(:send_email_to_vendor).with(:new_order, nil)
        subject.new_order
      end
    end
  end

  describe '#payment_link' do
    before do
      stub_request(:post, 'https://www.googleapis.com/urlshortener/v1/url')
    end

    it do
      expect(subject).to receive(:send_sms).once
      expect(subject).to receive(:send_email_to_client).with(:payment_link, nil)
      subject.payment_link
    end
  end

  describe '#order_paid' do
    it do
      expect(subject).to receive(:send_sms).twice
      expect(subject).to receive(:send_email_to_client).with(:paid, nil)
      expect(subject).to receive(:send_email_to_vendor).with(:paid, nil)
      subject.order_paid
    end
  end

  describe '#order_workflow_changed' do
    let(:workflow_was) { create :workflow_state }

    it do
      expect(subject).to receive(:send_sms).twice
      expect(subject).to receive(:send_email_to_client).with(:workflow_changed, workflow_was: workflow_was)
      subject.workflow_changed workflow_was: workflow_was
    end

    context 'магазин отключил увеломдения' do
      before do
        vendor.mail_templates.create! key: :workflow_changed, namespace: 'merchant', allow_sms: false, locale: vendor.default_locale
        vendor.mail_templates.create! key: :workflow_changed, namespace: 'client', allow_sms: false, locale: vendor.default_locale
      end

      it do
        expect(subject).not_to receive :send_sms
        subject.workflow_changed workflow_was: workflow_was
      end
    end
  end

  describe '#order_has_run_out_goods' do
    it do
      expect(subject).to receive(:send_sms).once
      expect(subject).to receive(:send_email_to_vendor).with(:run_out, nil)
      subject.order_has_run_out_goods
    end
  end
end
