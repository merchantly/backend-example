require 'rails_helper'

RSpec.describe VendorSmsLogEntity, type: :model do
  let_it_be(:vendor) { create :vendor, sms_count: 250 }

  it do
    expect(vendor.sms_count).to eq 250
  end

  context do
    it do
      create :vendor_sms_log_entity, sms_count: 100, vendor: vendor
      expect(vendor.reload.sms_count).to eq 150
    end
  end
end
