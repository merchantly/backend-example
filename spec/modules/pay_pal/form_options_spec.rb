require 'rails_helper'

describe PayPal::FormOptions do
  subject { described_class.new(order).generate }

  let!(:vendor) { create :vendor }
  let(:order) { create :order, :delivery_redexpress, :payment_pay_pal, vendor: vendor }

  it do
    expect(subject).to be_a Array
  end
end
