require 'rails_helper'

describe YandexKassa::FormOptions do
  let!(:vendor)      { create :vendor }
  let!(:price)       { 250.to_money }
  let!(:product)     { create :product, :ordering, vendor: vendor, price: price }
  let!(:order_item)  { create :order_item, order: order, good: product, price: price, count: 2 }

  let(:payment_type) { create :vendor_payment, :yandex_kassa, vendor: vendor, online_kassa_provider: :default }
  let(:order)        { create :order, :delivery_redexpress, vendor: vendor, payment_type: payment_type }

  let(:form_options) { order.reload; described_class.new(order).generate }
  let(:receipt)      { JSON.parse form_options.find { |e| e[0] == 'ym_merchant_receipt' }.second }

  before do
    order.reload # обновляем items
    order.update_prices!
  end

  it do
    expect(form_options).to be_a Array
  end

  context 'содержимое чека' do
    it 'суммы для yandex-kassa ККТ отдаются с двумя нулями' do
      expect(receipt).to be_a Hash
      expect(receipt['items']).to have(2).items
      expect(receipt['items'].first['quantity']).to eq 2
      expect(receipt['items'].first['price']['amount']).to eq price.to_i
    end
  end
end
