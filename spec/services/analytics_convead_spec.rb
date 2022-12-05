require 'rails_helper'

describe AnalyticsConvead, :vcr do
  subject { described_class.new vendor: vendor, app_key: app_key, domain: domain, guest_uid: guest_uid, client: client, path: path, title: title }

  let(:vendor)      { create :vendor }
  let(:app_key)     { 'd201374f8837211618a5729d6f489124' }
  let(:domain)      { 'kiiiosk.ru' }
  let(:visitor_uid) { 123 }
  let(:guest_uid)   { 123 }
  let(:path)        { '/some' }
  let(:title)       { 'page title' }
  let(:client)      { create :client }

  context 'view_product' do
    let(:product) { create :product }

    it do
      expect { subject.view_product(product) }.not_to raise_error
    end
  end

  context 'add_to_cart' do
    let(:cart_item) { create :cart_item }

    it do
      expect { subject.add_to_cart(cart_item) }.not_to raise_error
    end
  end

  context 'remove_from_cart' do
    let(:cart_item) { create :cart_item }

    it do
      expect { subject.remove_from_cart(cart_item) }.not_to raise_error
    end
  end

  context 'update_cart' do
    let(:cart) { create :cart }

    it do
      expect { subject.update_cart(cart) }.not_to raise_error
    end
  end

  context 'purchase' do
    let(:order) { create :order }

    it do
      expect { subject.purchase(order) }.not_to raise_error
    end
  end
end
