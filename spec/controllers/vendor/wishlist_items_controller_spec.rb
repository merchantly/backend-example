require 'rails_helper'

RSpec.describe Vendor::WishlistItemsController, type: :controller do
  include VendorControllerSupport

  let(:product)  { vendor.products.first }
  let(:wishlist) { create :wishlist, :with_items, items_count: 1, vendor: vendor }

  before { request.env['HTTP_REFERER'] = 'http://new.example.com:3000/back' }

  describe 'CREATE' do
    it do
      post :create, params: { good_id: product.global_id, use_route: 'wishlist/items' }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE' do
    let!(:wishlist_item) { create :wishlist_item, wishlist: wishlist, good_global_id: product.global_id }

    it do
      delete :destroy, params: { id: wishlist_item.id, good_id: product.global_id, use_route: 'wishlist/items/:id' }
      expect(response.status).to eq 302
    end
  end
end
