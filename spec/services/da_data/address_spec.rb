require 'rails_helper'

describe DaData::Address, :vcr do
  subject { described_class.new(raw_address: raw_address).call }

  describe '#call' do
    context 'valid address' do
      let(:raw_address) { 'мск сухонска 11/-89' }

      it 'returns parsed address' do
        expect(subject[:result]).to eq 'Россия, г Москва, ул Сухонская, д 11, кв 89'
      end
    end

    context 'invalid address' do
      let(:raw_address) { 'ere3eekjevb' }

      it 'returns empty result' do
        expect(subject[:result]).to eq nil
      end
    end
  end
end
