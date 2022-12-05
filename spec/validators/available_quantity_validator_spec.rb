require 'rails_helper'

RSpec.describe AvailableQuantityValidator do
  include CurrentVendor

  let!(:vendor) { create :vendor }
  let!(:cart) { create :cart, vendor: vendor }
  let(:attribute) { 'some' }
  let(:good) { create :product, :ordering, vendor: vendor, quantity: 1 }
  let(:record) { create :cart_item, cart: cart, good: good, count: 1 }

  before do
    set_current_vendor vendor
    described_class.new(attributes: [:a]).validate_each record, attribute, value
  end

  after do
    set_current_vendor nil
  end

  context 'valid quantity' do
    let(:value) { 1 }

    it do
      expect(record.errors).to be_empty
    end
  end

  context 'unvalid quantity' do
    let(:value) { 10 }

    it do
      expect(record.errors).not_to be_empty
    end
  end

  context 'not orderable product' do
    let(:value) { 1 }
    let(:good)   { create :product, vendor: vendor }
    let(:record) { create :cart_item, cart: cart, good: good }

    it do
      expect(record.errors).not_to be_empty
    end
  end
end
