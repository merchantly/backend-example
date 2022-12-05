require 'rails_helper'

RSpec.describe VendorOrderField, type: :model do
  subject { create :vendor_order_field }

  it do
    expect(subject).to be_persisted
  end
end
