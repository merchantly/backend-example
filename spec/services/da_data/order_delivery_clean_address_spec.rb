require 'rails_helper'

describe DaData::OrderDeliveryCleanAddress do
  subject { described_class.new(order: order, address_service: address_service).call }

  let!(:order) { create :order }

  describe '#call' do
    context 'undetermined address' do
      let(:address_service) { -> { { fias_level: 7 } } }

      it 'must raise error' do
        expect { subject }.to raise_error DaDataError::UndeterminedAddress
      end
    end

    context 'valid address' do
      let(:results) do
        {
          street: 'Миттова',
          house: 9,
          flat: 12,
          fias_level: 8
        }
      end
      let(:address_service) { -> { results } }

      before { subject }

      it 'updates order delivery address fields' do
        expect(order.street).to eq results[:street]
        expect(order.house).to eq results[:house].to_s
        expect(order.room).to eq results[:flat]
        expect(order).to be_address_parsed
      end
    end
  end
end
