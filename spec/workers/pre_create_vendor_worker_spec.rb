require 'rails_helper'

describe PreCreateVendorWorker do
  subject do
    vendor_template
    described_class
  end

  let(:vendor_template) { create :vendor_template }

  before do
    allow_any_instance_of(VendorCss).to receive :save
  end

  it do
    expect { subject.new.perform }.to change(Vendor, :count)
  end
end
