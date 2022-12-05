require 'rails_helper'

RSpec.describe VendorBells::VendorBell, type: :model do
  subject do
    vendor.bells.create! key: 'aaa'
  end

  let(:vendor) { create :vendor }

  it do
    expect(subject).to be_persisted
    expect(subject.subject).to be_present
    expect(subject.url).to be_present
    expect(subject.text).to be_present
  end
end
