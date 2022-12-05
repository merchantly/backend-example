require 'rails_helper'

RSpec.describe VendorDashboard, type: :model do
  subject { vendor }

  let!(:vendor) { create :vendor }

  it { expect(vendor.checked_dashboard_items).to eq [] }

  context 'check' do
    it do
      vendor.check_dashboard_item! 'test'
      expect(vendor.checked_dashboard_items).to include 'test'
    end
  end

  context 'uncheck' do
    before { vendor.check_dashboard_item! 'test' }

    it do
      vendor.uncheck_dashboard_item! 'test'
      expect(vendor.checked_dashboard_items).not_to include 'test'
    end
  end
end
