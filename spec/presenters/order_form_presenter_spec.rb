require 'rails_helper'

RSpec.describe OrderFormPresenter, type: :presenter do
  subject do
    described_class.new(
      cart: cart, order_form: order_form
    ).build
  end

  let(:vendor)               { create :vendor, :payments_and_deliveries_remote }
  let(:cart)                 { create :cart, :items, vendor: vendor }
  let(:vendor_delivery)      { create :vendor_delivery, vendor: vendor }
  let(:payment_type)         { create :vendor_payment, vendor: vendor }

  let(:order_form_attrs) do
    { vendor: vendor,
      'delivery_type_id' => vendor_delivery.id,
      'payment_type_id' => payment_type.id }
  end
  let(:order) { attributes_for :order, vendor: vendor, payment_type_id: payment_type.id, delivery_type_id: vendor_delivery.id }
  let(:order_form) do
    VendorOrderForm.new(
      order.merge(
        cart: cart, vendor: vendor, locale: vendor.default_locale,
        coupon_code: coupon.code
      )
    )
  end

  before do
    Thread.current[:vendor] = vendor
  end

  context 'with coupon_free_delivery' do
    let(:coupon) { create :coupon_free_delivery, vendor: vendor }

    it do
      subject.deliveryTypes.each do |delivery_type|
        expect(delivery_type[:freeDeliveryThreshold]).to eq API::Entity::SmartMoney.represent(vendor.zero_money).as_json
      end
    end
  end

  context 'with free_delivery_threshold' do
    let(:coupon) { create :coupon_single, vendor: vendor }
    let(:vendor_delivery) { create :vendor_delivery, vendor: vendor, free_delivery_threshold: Money.new(1, :rub) }

    it do
      expect(subject.deliveryTypes.last[:freeDeliveryThreshold]).to eq nil
      expect(subject.deliveryTypes.first[:freeDeliveryThreshold]).to eq API::Entity::SmartMoney.represent(vendor_delivery.free_delivery_threshold).as_json
    end
  end

  context 'with coupon_single' do
    let(:coupon) { create :coupon_single, vendor: vendor }

    it do
      subject.deliveryTypes.each do |delivery_type|
        expect(delivery_type[:freeDeliveryThreshold]).to be_nil
      end
    end
  end
end
