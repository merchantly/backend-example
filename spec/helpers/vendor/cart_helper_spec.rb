require 'rails_helper'

describe Vendor::CartHelper do
  helper described_class
  subject { helper.amount_collection item }

  let!(:vendor) { create :vendor }
  let(:cart) { create :cart, vendor: vendor }
  let(:good) { create :product, :ordering, vendor: vendor, quantity: 1 }
  let(:item) { create :cart_item, cart: cart, good: good }

  before do
    allow(helper).to receive(:current_vendor).and_return(vendor)
  end

  it do
    expect(subject).to eq '<option value="1" selected="selected">1</option>'
  end
end
