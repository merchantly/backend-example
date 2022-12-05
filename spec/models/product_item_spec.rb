require 'rails_helper'

RSpec.describe ProductItem, type: :model do
  context do
    let(:product_item) { create :product_item, attrs }

    let(:count) { 4 }
    let(:attrs) { { count: count } }

    it 'запоминает размер' do
      expect(product_item.count).to eq count
    end
  end

  context 'zero quantity' do
    subject { create :product_item, quantity: 0 }

    it { expect(subject.quantity).to eq 0 }
  end
end
