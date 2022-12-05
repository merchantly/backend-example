require 'rails_helper'

describe Redexpress::DeliveryState do
  subject { described_class.new(order.order_delivery).get_state }

  let!(:order) { create :order, :delivery_redexpress }

  before do
    stub_request(:get, "http://redexpressservice.ru:9081/rxwbm/invoiceinfo?mailcode=#{order.order_delivery.tracking_id}")
      .to_return(status: 200, body: File.new(response_file))
  end

  # before do
  # stub_request(:get, /#{Regexp.quote(URI.parse(Redexpress::DeliveryState::API_URL).host)}/).to_rack(RedexpressApiMock.new)
  # end

  context 'correct params' do
    context 'regular' do
      let(:response_file) { './spec/fixtures/redexpress/found.xml' }

      it 'gets order status' do
        expect(subject).to be_persisted
        expect(subject.description).to eq('Груз был доставлен получателю')
        expect(subject.time).to be_a Time
      end
    end

    context 'awaits' do
      let(:response_file) { './spec/fixtures/redexpress/awaits.xml' }

      it 'gets order status' do
        expect(subject).to be_persisted
        expect(subject.description).to eq('Ожидает подтверждения ')
        expect(subject.time).to be_a Time
        expect(subject.time + 1.day).to be > Time.zone.now
      end
    end
  end

  context 'incorrect params' do
    let(:response_file) { './spec/fixtures/redexpress/not_found.xml' }

    it 'does not get order status' do
      expect(subject).not_to be_persisted
    end
  end

  context 'empty params' do
    let(:response_file) { './spec/fixtures/redexpress/error.txt' }

    it 'does not get order status' do
      expect { subject }.to raise_error(Redexpress::DeliveryState::Error)
    end
  end
end
