require 'rails_helper'

RSpec.describe Wishlist, type: :model do
  subject { wishlist }

  let(:vendor)    { create :vendor }
  let(:product)   { create :product, vendor: vendor }
  let!(:wishlist) { create :wishlist, :with_items, items_count: 2, vendor: vendor }

  describe '#goods' do
    let(:wishlist) { create :wishlist, vendor: vendor }
    let!(:wishlist_item) { create :wishlist_item, wishlist: wishlist, good_global_id: product.global_id }

    it 'must return goods' do
      expect(subject.goods).to include product
    end
  end

  describe '#add_item' do
    before { subject.add_item product.global_id }

    it 'must add item' do
      expect(wishlist.reload.items.count).to eq 3
    end
  end

  describe '#remove_item' do
    before { subject.remove_item wishlist.items.last.good_global_id }

    it 'must add item' do
      expect(wishlist.reload.items.count).to eq 1
    end
  end
end
