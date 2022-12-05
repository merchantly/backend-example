require 'rails_helper'

# плавают тесты
# http://i.gyazo.com/ce695f045f1eeb9941c3b64a2bc772ac.png

describe W1::OrderDeliveryUpdateService do
  subject { described_class.new order }

  let!(:order) { create :order, :delivery_redexpress }

  it 'контролька' do
    expect(order.order_delivery.state).to eq OrderDelivery::STATE_NEW
  end

  describe do
    before do
      stub_request(:post, 'https://api.w1.ru/OpenApi/order/state')
        .with(body: { 'OrderId' => order.id.to_s })
        .to_return(File.new(response_file))
    end

    describe 'done' do
      let(:response_file) { './spec/fixtures/w1/update_state_done.raw' }

      it do
        subject.update_state
        expect(order.order_delivery.state).to eq(OrderDelivery::STATE_DONE)
      end

      it do
        expect(W1.logger).not_to receive(:error)
        expect(order.commands).to receive(:update_delivery_state_to_done!)
        subject.update_state
      end
    end

    describe 'delivery' do
      let(:response_file) { './spec/fixtures/w1/update_state_delivery.raw' }

      it do
        expect(W1.logger).not_to receive(:error)
        expect(order.commands).to receive(:update_delivery_state_to_delivery!)
        subject.update_state
      end
    end

    describe 'wrong' do
      let(:response_file) { './spec/fixtures/w1/wrong.raw' }

      it do
        expect(W1.logger).to receive(:error)
        expect(order.commands).not_to receive(:update_delivery_state_to_delivery!)
        expect(order.commands).not_to receive(:update_delivery_state_to_done!)
        expect { subject.update_state }.to raise_exception W1::OrderDeliveryUpdateService::Error
        expect(order.order_delivery.state).to eq(OrderDelivery::STATE_NEW)
      end
    end
  end
end
