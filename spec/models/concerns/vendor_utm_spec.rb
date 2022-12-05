require 'rails_helper'

RSpec.describe VendorUtm, type: :model do
  subject { vendor.init_utm }

  let(:utm_source) { generate :utm }

  context 'read' do
    subject { vendor.init_utm }

    let(:vendor) { build :vendor, init_utm_source: utm_source }

    it do
      expect(vendor.init_utm).to be_present
      expect(vendor.init_utm.utm_source).to eq utm_source
    end
  end
end
