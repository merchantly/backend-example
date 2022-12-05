require 'rails_helper'

describe CSE::DeliveryState do
  subject { described_class.new(order.order_delivery).get_state }

  let!(:order) { create :order, :delivery_cse }

  before { order.order_delivery.update_column :external_id, '999-0002208013' }

  context 'correct params' do
    it 'gets order status' do
      VCR.use_cassette('cse_state_200') do
        expect(subject.error).to be false
      end
    end
  end

  context 'not authorized' do
    before { order.order_delivery.delivery_type.update! login: 'very', password: 'bad' }

    it 'does not get order status' do
      VCR.use_cassette('cse_state_401') do
        expect { subject }.to raise_error(CSE::DeliveryState::Error)
      end
    end
  end

  context 'wrong order number' do
    before { order.order_delivery.update_column :external_id, '12312313' }

    it 'does not get order status' do
      VCR.use_cassette('cse_state_400') do
        expect { subject }.to raise_error(CSE::DeliveryState::Error)
      end
    end
  end

  context 'no external_id' do
    before { order.order_delivery.update_column :external_id, nil }

    it 'raises exception' do
      expect { subject }.to raise_exception(CSE::DeliveryState::NoExternalId)
    end
  end
end
