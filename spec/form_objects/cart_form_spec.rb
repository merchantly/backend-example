require 'rails_helper'

RSpec.describe CartForm, type: :model do
  include CurrentVendor

  subject { described_class.new cart }

  let(:vendor) { create :vendor }

  before do
    set_current_vendor vendor
  end

  context do
    let(:cart) { create :cart }

    it 'форма козрины инвалидная, потому что в ней нет items' do
      expect(subject).not_to be_valid
    end
  end

  context do
    let(:cart) { create :cart, :items }

    it { expect(subject).to be_valid }
  end

  context 'minimal price' do
    let(:vendor) { create :vendor, :with_minimal_price }
    let(:cart) { create :cart, :items, vendor: vendor }

    it { expect(subject).not_to be_valid }
  end
end
