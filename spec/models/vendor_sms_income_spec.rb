require 'rails_helper'

RSpec.describe VendorSmsIncome, type: :model do
  let_it_be(:vendor) { create :vendor }
  it do
    expect(vendor.sms_count).to eq 0
  end

  context do
    let(:vsm) { create :vendor_sms_income, vendor: vendor, count: 100 }

    it do
      expect(vsm.vendor.reload.sms_count).to eq 100
    end
  end
end
