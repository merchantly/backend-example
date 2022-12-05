require 'rails_helper'

describe OrderCreator do
  include CurrentVendor

  subject(:creator) { described_class.new(order_form, visit_id: visit_id, session_id: session_id, visit_sources_ids: visit_sources_ids).perform }

  let(:items_price) { Money.new 3000, :rub }
  let(:vendor)           { create :vendor, :payments_and_deliveries_remote }
  let(:cart)             { create :cart, :items, vendor: vendor }
  let(:delivery_type)    { create :vendor_delivery, vendor: vendor }
  let(:payment_type) { create :vendor_payment, vendor: vendor }
  let(:order_form_attrs) do
    { vendor: vendor,
      'delivery_type_id' => delivery_type.id,
      'payment_type_id' => payment_type.id }
  end
  let(:order)            { (attributes_for :order, vendor: vendor, payment_type_id: payment_type.id, delivery_type_id: delivery_type.id).except(:client) }
  let(:order_form)       { VendorOrderForm.new order.merge cart: cart, vendor: vendor, locale: vendor.default_locale }
  let(:visit_id) { '123' }
  let(:session_id) { '123' }
  let(:visit_sources_ids) { [1, 2] }

  before do
    ActiveJob::Base.queue_adapter = :test
    set_current_vendor vendor
    allow_any_instance_of(described_class).to receive(:parse_delivery_address)
  end

  shared_examples_for 'prices' do
    it do
      expect(cart.products_price).to eq items_price
      expect(creator.products_price).to eq items_price
    end
  end

  describe do
    specify do
      expect(creator).to be_a Order
      expect(creator).to be_persisted
      expect(creator.items).to have(3).items
    end

    describe 'client creation' do
      context 'phone client exist' do
        let!(:client) { create :client, vendor: vendor, phones_attributes: { 0 => { phone: order[:phone] } } }

        it 'must find client' do
          expect(creator.client).to eq client
        end
      end

      context 'email client exist' do
        let!(:client) { create :client, vendor: vendor, emails_attributes: { 0 => { email: order[:email] } } }

        it 'must find client' do
          expect(creator.client).to eq client
        end
      end

      context 'client not exist' do
        let(:email) { generate :email }
        let(:order) { (attributes_for :order, vendor: vendor, email: email, payment_type_id: payment_type.id, delivery_type_id: delivery_type.id).except(:client) }

        it 'must create client' do
          expect(creator.client.emails_array).to include email
        end
      end
    end

    context 'unorderable' do
      subject { described_class.new(order_form, visit_id: visit_id, session_id: session_id, visit_sources_ids: visit_sources_ids).perform }

      let(:cart) { create :cart, :unorderable_items }

      it do
        expect { subject }.to raise_error CartHasUnorderableItemsError
      end
    end

    context 'comment presence' do
      let!(:payment_type)  { create :vendor_payment, :w1, vendor: vendor, title: vendor.name }
      let!(:delivery_type) { create :vendor_delivery, :cse, vendor: vendor, is_comment_required: true, title: vendor.name }

      let(:vendor) { create :vendor }
      let(:order) { (attributes_for :order, comment: comment, vendor: vendor, payment_type_id: payment_type.id, delivery_type_id: delivery_type.id).except(:client) }

      context 'valid' do
        let(:comment) { '' }

        it do
          expect { subject }.to raise_error InvalidFormError
        end
      end

      context 'invalid' do
        let(:comment) { 'test' }

        it do
          expect { subject }.not_to raise_error
        end
      end
    end

    include_examples 'prices'

    context 'у товара изменилась цена, но в заказе и в корзине она не изменилась' do
      subject do
        product.update! :price, product.price * 2
      end

      let(:product) { cart.items.first.product }

      include_examples 'prices'
    end
  end

  describe 'free delivery' do
    context 'threshold 0' do
      before { order_form.delivery_type.update_attribute :free_delivery_threshold, Money.new(0) }

      it 'must not apply free delivery' do
        expect(creator.delivery_price).to be > 0
        expect(creator.free_delivery_threshold).to eq 0
      end
    end

    context 'price < threshold' do
      let(:threshold) { Money.new(1_000_000) }

      before { order_form.delivery_type.update_attribute :free_delivery_threshold, threshold }

      it 'must not apply free delivery' do
        expect(creator.delivery_price).to be > 0
        expect(creator.free_delivery_threshold).to eq threshold
      end
    end

    context 'price > threshold' do
      let(:threshold) { Money.new(10) }

      before { order_form.delivery_type.update_attribute :free_delivery_threshold, threshold }

      it 'must apply free delivery' do
        expect(creator.delivery_price).to eq 0
        expect(creator.free_delivery_threshold).to eq threshold
      end
    end
  end

  describe '#parse_delivery_address_if_needed' do
    context 'vendor.clean_order_address = false' do
      before do
        vendor.update_column :clean_order_address, false
      end

      it 'must not parse_delivery_address' do
        expect_any_instance_of(described_class).not_to receive(:parse_delivery_address)
        creator
      end
    end

    context 'vendor.clean_order_address = true' do
      before do
        vendor.update_column :clean_order_address, true
      end

      it 'must parse_delivery_address' do
        expect_any_instance_of(described_class).to receive(:parse_delivery_address)
        creator
      end

      context 'OrderDeliveryPickup' do
        let(:delivery_type) { create :vendor_delivery, :pickup, vendor: vendor }

        it 'must not parse_delivery_address' do
          expect_any_instance_of(described_class).not_to receive(:parse_delivery_address)
          creator
        end
      end
    end
  end

  describe 'coupons' do
    let(:vendor) { create :vendor, :with_clients, :with_orders }

    context 'бесплатная доставка с условными купонами' do
      let(:products_behavior) { Coupon::USE_BEHAVIOR_INCLUDE }
      let(:coupon) { create :coupon_free_delivery, discount: 10, vendor: vendor, product_ids: [cart.items.first.product_id], use_products_behavior: products_behavior }
      let(:order_form) { VendorOrderForm.new order.merge(address: 'test test1', email: 'test123@gmail.com', phone: '12312312312', coupon_code: coupon.code, cart: cart, vendor: vendor, locale: vendor.default_locale) }

      it do
        expect(creator.delivery_price).to eq 0.to_money
      end

      it do
        expect(creator.coupon).to eq coupon
      end
    end

    context 'бесплатная доставка не действует, если условный купон не позволяет (все товары исключены)' do
      let(:products_behavior) { Coupon::USE_BEHAVIOR_EXCLUDE }
      let(:coupon) { create :coupon_free_delivery, discount: 10, vendor: vendor, product_ids: cart.items.map(&:product_id), use_products_behavior: products_behavior }
      let(:order_form) { VendorOrderForm.new order.merge(address: 'test test1', email: 'test123@gmail.com', phone: '12312312312', coupon_code: coupon.code, cart: cart, vendor: vendor, locale: vendor.default_locale) }

      it do
        expect(creator.delivery_price).not_to eq 0.to_money
      end
    end

    context 'discount_type fixed' do
      let(:coupon) { create :coupon_single, discount: 10, vendor: vendor, discount_type: 'fixed' }
      let(:order_form) { VendorOrderForm.new order.merge(address: 'test test1', email: 'test123@gmail.com', phone: '12312312312', coupon_code: coupon.code, cart: cart, vendor: vendor, locale: vendor.default_locale) }

      it do
        expect { creator }.not_to raise_error
      end

      it do
        order = creator
        expect(order.total_price).to eq order.products_price - coupon.discount_price
      end

      include_examples 'prices'
    end

    context 'only for first order, orders count 0' do
      let(:coupon) { create :coupon_single, only_first_order: true, vendor: vendor }
      let(:order_form) { VendorOrderForm.new order.merge(address: 'test test1', email: 'test123@gmail.com', phone: '12312312312', coupon_code: coupon.code, cart: cart, vendor: vendor, locale: vendor.default_locale) }

      it do
        expect { creator }.not_to raise_error
      end
    end

    context 'only for first order, orders count > 1' do
      let(:coupon) { create :coupon_single, only_first_order: true, vendor: vendor }
      let(:client) { vendor.orders.first.client }
      let(:order_form) do
        VendorOrderForm.new(
          order.merge(
            coupon_code: coupon.code, cart: cart,
            vendor: vendor, locale: vendor.default_locale,
            email: client.email.to_s
          )
        )
      end

      it do
        expect { creator }.to raise_error Coupon::NotFirstOrderCouponError
      end
    end

    context 'only for first order, check address, orders count > 1' do
      let(:coupon) { create :coupon_single, only_first_order: true, is_check_address: true, vendor: vendor }
      let(:client) { vendor.orders.first.client }
      let(:order_form) do
        VendorOrderForm.new(
          order.merge(
            coupon_code: coupon.code, cart: cart,
            vendor: vendor, locale: vendor.default_locale,
            email: 'test123@gmail.com', phone: '12312312312' # отличные от клиента
          )
        )
      end

      it do
        expect { creator }.to raise_error Coupon::NotFirstOrderCouponError
      end
    end

    context 'only for first order, check address, orders count = 0' do
      let(:coupon) { create :coupon_single, only_first_order: true, is_check_address: true, vendor: vendor }
      let(:client) { vendor.orders.first.client }
      let(:order_form) do
        VendorOrderForm.new(
          order.merge(
            coupon_code: coupon.code, cart: cart, address: 'test',
            vendor: vendor, locale: vendor.default_locale,
            email: 'test123@gmail.com', phone: '12312312312'
          )
        )
      end

      it do
        expect { creator }.not_to raise_error
      end
    end

    context 'only for first order = false, orders count 0' do
      let(:coupon) { create :coupon_single, only_first_order: false, vendor: vendor }
      let(:order_form) { VendorOrderForm.new order.merge(coupon_code: coupon.code, cart: cart, vendor: vendor, locale: vendor.default_locale) }

      it do
        expect { creator }.not_to raise_error
      end
    end

    context 'only for first order = false, orders count > 1' do
      let(:coupon) { create :coupon_single, only_first_order: false, vendor: vendor }
      let(:client) { vendor.orders.first.client }
      let(:order_form) do
        VendorOrderForm.new(
          order.merge(
            coupon_code: coupon.code, cart: cart,
            vendor: vendor, locale: vendor.default_locale, email: client.email.to_s
          )
        )
      end

      it do
        expect { creator }.not_to raise_error
      end
    end

    context 'minimal products count right' do
      let(:coupon) { create :coupon_single, vendor: vendor, minimal_products_count: 3 }
      let(:client) { vendor.orders.first.client }
      let(:order_form) do
        VendorOrderForm.new(
          order.merge(
            coupon_code: coupon.code, cart: cart,
            vendor: vendor, locale: vendor.default_locale, email: client.email.to_s
          )
        )
      end

      it do
        expect { creator }.not_to raise_error
      end
    end

    context 'minimal products count not right' do
      let(:coupon) { create :coupon_single, vendor: vendor, minimal_products_count: 4 }
      let(:client) { vendor.orders.first.client }
      let(:order_form) do
        VendorOrderForm.new(
          order.merge(
            coupon_code: coupon.code, cart: cart,
            vendor: vendor, locale: vendor.default_locale, email: client.email.to_s
          )
        )
      end

      it do
        expect { creator }.to raise_error Coupon::MinimalProductsCountCouponError
      end
    end
  end

  describe do
    let!(:order_form) do
      VendorOrderForm.new order.merge cart: cart, vendor: vendor, locale: vendor.default_locale
    end

    context 'performance test' do
      before do
        Sidekiq::Worker.clear_all
        Sidekiq::Testing.fake!
      end

      # TODO Сократить то 10 запросов
      it do
        expect do
          described_class.new(order_form, visit_id: visit_id, session_id: session_id, visit_sources_ids: visit_sources_ids).perform
        end.not_to exceed_query_limit(79)

        expect(OrderCreatedWorker.jobs.size).to eq 1
        expect(Sidekiq::Worker.jobs.size).to eq 2
      end
    end
  end
end
