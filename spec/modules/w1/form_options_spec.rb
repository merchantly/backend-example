require 'rails_helper'

describe W1::FormOptions do
  subject { described_class.new(order).generate }

  let!(:vendor) { create :vendor }
  let(:order) { create :order, :delivery_redexpress, vendor: vendor }

  it do
    expect(subject).to be_a Array
  end

  describe 'без доставки' do
    it do
      expect(subject.to_s).not_to include 'WMI_DELIVERY_REQUEST'
    end
  end
end
