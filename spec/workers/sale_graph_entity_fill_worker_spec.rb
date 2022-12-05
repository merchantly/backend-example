require 'rails_helper'

describe SaleGraphEntityFillWorker do
  subject do
    described_class.new
  end

  describe '#perform' do
    it do
      expect { subject.perform }.not_to raise_error
      expect(SaleGraphEntity.count).to eq(1)
    end
  end
end
