require 'rails_helper'

RSpec.describe Vendor::CartController, type: :controller do
  include VendorControllerSupport

  let!(:cart) { create :cart, vendor: vendor }

  before do
    allow_any_instance_of(CartService).to receive(:find_cart).and_return cart
    vendor.theme.update! engine: VendorTheme::LIQUID_ENGINE
  end

  it 'show' do
    get :show
    expect(response).to be_ok
  end

  describe '#update' do
    it 'данных не достаточно, корзина показывается снова' do
      put :update
      expect(response).to be_ok
      expect(response).to render_template('vendor/cart/show')
    end
  end

  describe '#update' do
    let!(:good) { create :product, :ordering, vendor: vendor }
    let!(:cart_item) { create :cart_item, cart: cart, good: good }

    it 'переходим на заказ' do
      put :update
      expect(response).to be_ok
      expect(response).to render_template('vendor/orders/new')
    end
  end

  it 'clean' do
    delete :destroy
    expect(response).to be_redirection
  end
end
