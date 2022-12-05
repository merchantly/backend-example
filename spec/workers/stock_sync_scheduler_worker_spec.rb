require 'rails_helper'

describe StockSyncSchedulerWorker do
  let!(:vendor) { create :vendor }

  describe '#cancel_hanged' do
    subject { described_class.new.send :cancel_hanged }

    let!(:entity) { vendor.stock_importing_log_entities.create! updated_at: last_updated_at }
    let!(:last_updated_at) { Time.zone.now - StockImportingLogEntity::HANGING_PERIOD }
    let!(:entities) { [entity] }

    it do
      scope = double
      allow(scope).to receive(:find_each).and_yield(entity)
      expect(StockImportingLogEntity).to receive(:hanged).and_return scope
      expect(entity).to receive(:cancel!)
      # expect_any_instance_of(StockImportingLogEntity).to receive(:cancel!)
      described_class.new.perform
    end
  end
end
