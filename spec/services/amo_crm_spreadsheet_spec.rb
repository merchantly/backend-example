require 'rails_helper'

describe AmoCrmSpreadsheet do
  subject { described_class.new orders }

  let!(:vendor) { create :vendor }
  let!(:order)  { create :order, :items, vendor: vendor, name: 'Developement' }
  let!(:orders) { vendor.orders }

  it do
    expect(subject.to_csv).to be_a String
    expect(subject.to_csv.lines).to have(2).items
  end
end
