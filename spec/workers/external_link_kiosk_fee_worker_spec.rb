require 'rails_helper'

describe ExternalLinkKioskFeeWorker do
  subject { described_class.new }

  let(:vendor) { create :vendor, :with_tariff }

  it do
    expect(OpenbillTransaction).to receive(:create!)
    subject.perform(vendor.id)
  end
end
