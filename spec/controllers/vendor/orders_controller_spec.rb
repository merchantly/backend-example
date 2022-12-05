require 'rails_helper'

RSpec.describe Vendor::OrdersController, type: :controller do
  include VendorControllerSupport

  let!(:payment_type_custom) { create :vendor_payment, :custom, vendor: vendor }
  let!(:payment_type_w1) { create :vendor_payment, :w1, vendor: vendor }
  let!(:payment_type_pay_pal) { create :vendor_payment, :pay_pal, vendor: vendor }
  let!(:delivery_type) { create :vendor_delivery, :cse, vendor: vendor }

  before do
    vendor.theme.update! engine: VendorTheme::LIQUID_ENGINE
  end

  describe '#create' do
    context 'с корзиной' do
      let!(:cart) { create :cart, vendor: vendor }
      let!(:cart_item) { create :cart_item, cart: cart, good: good }
      let(:order_form) { { name: 'Вася', city_title: 'Москва' } }

      before do
        allow(controller).to receive(:find_cart).and_return cart
      end

      context 'показывается форма заказа' do
        let!(:good) { create :product, :ordering, vendor: vendor }

        it 'так как форма не закончена, показываем форму' do
          post :create, params: { vendor_order: order_form }

          expect(response).to be_ok
          expect(response).to render_template('vendor/orders/new')
        end

        context 'удачный заказ OrderPaymentDirect с кастомным сообщением' do
          let(:order_form) { { payment_type_id: payment_type_custom.id, phone: '89033891228', email: 'test@test.com', name: 'Вася', address: 'Улица', city_title: 'Москва' } }

          it do
            post :create, params: { vendor_order: order_form }

            expect(response).to be_ok
            expect(response).to render_template('vendor/orders/custom')
            expect(response.body).to include 'на сумму'
          end
        end

        context 'удачный заказ OrderPaymentDirect' do
          let(:order_form) { { phone: '89033891228', email: 'test@test.com', name: 'Вася', address: 'Улица', city_title: 'Москва' } }

          it do
            post :create, params: { vendor_order: order_form }

            expect(response).to be_ok
            expect(response).to render_template('vendor/orders/created')
          end
        end

        context 'удачный заказ OrderPaymentW1' do
          let(:order_form) { { payment_type_id: payment_type_w1.id, phone: '89033891228', email: 'test@test.com', name: 'Вася', address: 'Улица', city_title: 'Москва' } }

          it do
            post :create, params: { vendor_order: order_form }

            expect(response).to be_ok
            expect(response).to render_template('vendor/orders/payment')
          end
        end

        context 'удачный заказ OrderPaymentPayPal' do
          let(:order_form) { { payment_type_id: payment_type_pay_pal.id, phone: '89033891228', email: 'test@test.com', name: 'Вася', address: 'Улица', city_title: 'Москва' } }

          it do
            post :create, params: { vendor_order: order_form }

            expect(response).to be_ok
            expect(response).to render_template('vendor/orders/payment')
          end
        end
      end

      context 'нет ни одного покупаемого товара' do
        let!(:good) { create :product, vendor: vendor }

        it do
          post :create, params: { vendor_order: order_form }

          expect(response).to be_redirection
          expect(response.redirect_url).to eq vendor_cart_url(host: vendor.host)
        end
      end
    end

    context 'без корзины' do
      it 'без параметров нет смысла' do
        expect { post :create }.to raise_error ActionController::ParameterMissing
      end

      it 'с пустой корзиной отправят обратно в корзину' do
        post :create, params: { vendor_order: { name: 'Вася' } }
        expect(response).to be_redirection
        expect(response.redirect_url).to eq vendor_cart_url(host: vendor.host)
      end
    end
  end

  describe '#show' do
    let(:delivery_type) { create :vendor_delivery, :cse, vendor: vendor }

    context 'w1 agent' do
      let(:payment_type) { create :vendor_payment, :w1, vendor: vendor }
      let(:order) { create :order, vendor: vendor, payment_type: payment_type, delivery_type: delivery_type }

      it do
        get :show, params: { id: order.external_id }
        expect(response).to be_ok
      end
    end

    context 'pay_pal agent' do
      let(:payment_type) { create :vendor_payment, :pay_pal, vendor: vendor }
      let(:order) { create :order, vendor: vendor, payment_type: payment_type, delivery_type: delivery_type }

      it do
        get :show, params: { id: order.external_id }
        expect(response).to be_ok
      end
    end
  end

  describe '#pay' do
    let(:delivery_type) { create :vendor_delivery, :cse, vendor: vendor }

    context 'w1 agent' do
      let(:order) { create :order, vendor: vendor, payment_type: payment_type_w1, delivery_type: delivery_type }

      it do
        get :pay, params: { id: order.external_id }
        expect(response).to be_ok
      end
    end

    context 'pay_pal agent' do
      let(:order) { create :order, vendor: vendor, payment_type: payment_type_pay_pal, delivery_type: delivery_type }

      it do
        get :pay, params: { id: order.external_id }
        expect(response).to be_ok
      end
    end
  end
end
