require 'rails_helper'

# при смене валюты запускается воркер для обновления валюты в товарах
RSpec.describe VendorCurrency, :vcr, type: :model do
  let(:old_cur_code) { 'UAH' }
  let(:new_cur_code) { 'EUR' }
  let!(:vendor) { create :vendor, :delivery, currency_iso_code: old_cur_code, available_currencies: [new_cur_code] }

  specify do
    expect(vendor.default_currency.iso_code).to eq old_cur_code
    expect(vendor.currency_iso_code).to eq old_cur_code
    expect(vendor.all_currencies.map(&:iso_code)).to eq [new_cur_code, old_cur_code]
    expect(vendor.minimal_price_currency).to eq old_cur_code
    expect(vendor.total_orders_price_currency).to eq old_cur_code
    expect(vendor.total_success_orders_price_currency).to eq old_cur_code
    expect(vendor.vendor_deliveries.last.price_currency).to eq old_cur_code
    expect(vendor.vendor_deliveries.last.free_delivery_threshold_currency).to eq old_cur_code

    expect(vendor).to receive(:update_currencies!)
    expect(vendor).to receive(:vendor_reindex)
    vendor.update_attribute :currency_iso_code, new_cur_code
  end

  describe '#update_currencies!' do
    before do
      create :product, vendor: vendor
    end

    specify do
      expect(vendor).to receive(:vendor_reindex)
      vendor.update_attribute :currency_iso_code, new_cur_code
      expect(vendor.currency_iso_code).to eq new_cur_code
      expect(vendor.minimal_price_currency).to eq new_cur_code
      expect(vendor.total_orders_price_currency).to eq new_cur_code
      expect(vendor.total_success_orders_price_currency).to eq new_cur_code
      expect(vendor.vendor_deliveries.last.price_currency).to eq new_cur_code
      expect(vendor.vendor_deliveries.last.free_delivery_threshold_currency).to eq new_cur_code
      expect(vendor.products.first.price.currency).to eq new_cur_code
      expect(vendor.products.first.sale_product_price.price_currency).to eq new_cur_code
    end
  end

  describe 'rate conversion' do
    it 'must convert rates' do
      expect { Money.new(100, :rub) > Money.new(100, :usd) }.not_to raise_error
    end
  end
end
