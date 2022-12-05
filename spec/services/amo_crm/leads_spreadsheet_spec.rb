require 'rails_helper'

describe AmoCrm::LeadsSpreadsheet do
  subject { described_class.new Vendor.all }

  let!(:vendor) { create :vendor, :with_operator }

  before do
    vendor.members.first.update_attribute :role, vendor.roles.owner
  end

  it do
    expect(subject.to_csv).to be_a String
    expect(subject.to_csv.lines).to have(2).items
  end
end
