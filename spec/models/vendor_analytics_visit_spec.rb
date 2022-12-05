require 'rails_helper'

RSpec.describe VendorAnalyticsVisit, type: :model do
  let(:vendor) { create :vendor }

  it 'пустой sources_ids' do
    expect(
      described_class.safe_create(
        id: '123',
        vendor_id: vendor.id,
        session_id: '123',
        user_agent: '',
        referer: '',
        remote_ip: '127.0.0.1',
        params: { a: 1 },
        sources_ids: [],
        created_at: Time.zone.now
      )
    ).to be_present
  end

  it 'НЕ пустой sources_ids' do
    expect(
      described_class.safe_create(
        id: '123',
        vendor_id: vendor.id,
        session_id: '123',
        user_agent: '',
        referer: '',
        remote_ip: '127.0.0.1',
        params: { a: 1 },
        sources_ids: [1, 2],
        created_at: Time.zone.now
      )
    ).to be_present
  end
end
