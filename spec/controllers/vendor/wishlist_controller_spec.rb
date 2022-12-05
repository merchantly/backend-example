require 'rails_helper'

RSpec.describe Vendor::WishlistController, type: :controller do
  include VendorControllerSupport

  let(:wishlist) { create :wishlist, :with_items, items_count: 1, vendor: vendor }

  before { request.env['HTTP_REFERER'] = 'http://new.example.com:3000/back' }

  describe 'GET index' do
    it do
      get :show
      expect(response.status).to eq 302
    end

    context 'by id' do
      let(:wishlist) { create :wishlist, vendor: vendor }
      let(:product) { vendor.products.first }
      let!(:wishlist_item) { create :wishlist_item, wishlist: wishlist, good_global_id: product.global_id }

      it 'returns http success' do
        get :show, params: { id: wishlist.slug }
        expect(response.status).to eq 200
      end
    end
  end
end
