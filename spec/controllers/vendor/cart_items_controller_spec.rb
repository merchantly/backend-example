require 'rails_helper'

RSpec.describe Vendor::CartItemsController, type: :controller do
  include VendorControllerSupport

  let!(:cart)      { create :cart, vendor: vendor }
  let!(:cart_item) { create :cart_item, cart: cart, good: good }

  context 'товары поштучно' do
    let!(:good) { create :product, vendor: vendor }

    it 'create' do
      post :create, params: { cart_item: { good_id: good.global_id, product_price_id: good.default_product_price.id } }
      expect(response).to be_redirection
    end

    it 'update' do
      put :update, params: { id: cart_item.id, cart_item: { good_id: good.global_id, count: 3, product_price_id: good.default_product_price.id } }
      expect(response).to be_redirection
    end

    it 'destroy' do
      get :destroy, params: { id: cart_item.id }
      expect(response).to be_redirection
    end
  end

  context 'товары на развес' do
    let!(:good)      { create :product, vendor: vendor, selling_by_weight: true, weight_of_price: 1 }

    it 'create' do
      post :create, params: { cart_item: { good_id: good.global_id, weight: 2.5, product_price_id: good.default_product_price.id } }
      expect(response).to be_redirection
    end

    it 'update' do
      put :update, params: { id: cart_item.id, cart_item: { good_id: good.global_id, count: 1, weight: 2.5, product_price_id: good.default_product_price.id } }
      expect(response).to be_redirection
    end

    it 'destroy' do
      get :destroy, params: { id: cart_item.id }
      expect(response).to be_redirection
    end
  end
end
