require 'rails_helper'

describe DefaultDictionaries do
  let(:vendor) { create :vendor }

  before do
    described_class.new(vendor).perform
  end

  it do
    expect(vendor.dictionaries).to have(3).items
  end
end
