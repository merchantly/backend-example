require 'rails_helper'

RSpec.describe StockImportingLogEntity, type: :model do
  subject { vendor.stock_importing_log_entities.create! }

  let!(:vendor) { create :vendor }

  it do
    expect(subject.state).to eq StockImportingLogEntity::STATE_STARTED
  end

  it '#cancel!' do
    subject.cancel!

    expect(subject.reload.state).to eq StockImportingLogEntity::STATE_CANCEL
  end
end
