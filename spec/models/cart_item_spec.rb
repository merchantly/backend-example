require 'rails_helper'

RSpec.describe CartItem, type: :model do
  subject { create :cart_item, good: good }

  shared_examples 'item with good' do
    it do
      expect(subject.title).to be_a String
    end

    it do
      expect(subject.image).to be_a ProductImage
    end
  end

  context 'good is Product' do
    let(:good) { create :product }
  end

  context 'good is ProductItem' do
    let(:good) { create :product_item }

    it_behaves_like 'item with good'
  end

  describe '#is_ordering' do
    let(:good) { create :product_item }

    it do
      expect(subject.is_ordering).to be_falsey
    end
  end
end
