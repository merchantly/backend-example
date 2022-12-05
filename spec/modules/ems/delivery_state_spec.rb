require 'rails_helper'

describe EMS::DeliveryState do
  subject { described_class.new(order.order_delivery).get_state }

  let!(:order) { create :order, :delivery_ems }

  before { order.order_delivery.update_column :external_id, 'EA338712012RU' }

  context 'correct params' do
    it 'gets order status' do
      VCR.use_cassette('ems_state_200') do
        expect(subject.count).to be > 0
      end
    end
  end

  context 'wrong order number' do
    before { order.order_delivery.update_column :external_id, '12312313' }

    it 'does not get order status' do
      VCR.use_cassette('ems_state_400') do
        expect { subject }.to raise_error(EMS::DeliveryState::Error)
      end
    end
  end

  context 'no external_id' do
    before { order.order_delivery.update_column :external_id, nil }

    it 'raises exception' do
      expect { subject }.to raise_exception(EMS::DeliveryState::NoExternalId)
    end
  end
end
