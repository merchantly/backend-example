require 'rails_helper'

RSpec.describe StockImportingLogEntity, type: :model do
  subject! { create :stock_importing_log_entity }

  it { expect(subject).to be_a described_class }
  it { expect(subject.data).to eq({}) }

  context 'stats' do
    it { expect(subject.stats).to be_a StockImportingStats }
  end

  context 'update_data' do
    it do
      subject.update_data! a: 1
      expect(subject.data).to eq('a' => '1')

      subject.update_data! a: '+1'
      expect(subject.data).to eq('a' => '2')
    end
  end
end
