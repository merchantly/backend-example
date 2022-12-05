require 'rails_helper'

describe ClientsSpreadsheet do
  subject       { described_class.new vendor.clients, vendor: vendor }

  let!(:vendor) { create :vendor, :with_clients }

  it do
    expect(subject.to_csv).to be_a String
    expect(subject.to_csv.lines).to have(4).items
  end
end
