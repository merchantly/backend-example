require 'rails_helper'

describe DefaultOrderConditions do
  let(:vendor) { create :vendor }

  before do
    described_class.new(vendor).perform
  end

  it do
    expect(vendor.order_conditions).to have(4).items
  end
end
