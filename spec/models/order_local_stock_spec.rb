require 'rails_helper'

RSpec.describe OrderLocalStock, type: :model do
  include CurrentVendor

  let_it_be(:vendor) { create :vendor }
  subject { order.order_local_stock }

  let!(:order) { create :order, :items, :payment_w1, vendor: vendor }
  let(:good) { order.items.first.good }

  before do
    set_current_vendor vendor
  end

  describe '#local_reserve' do
    context do
      it do
        expect(good.quantity).to eq 1
      end

      it do
        subject.reserve!
        expect(good.reload.quantity).to eq 0
      end
    end

    context 'negative reserve' do
      before do
        good.update_column :quantity, 0
      end

      it 'must notify vendor' do
        operator = vendor.operators.create! name: 'example', email: 'example@gmail.com'
        operator.update_column :email_confirmed_at, Time.zone.now

        expect(CustomOrderMailer).to receive(:send_merchant_mail).with('run_out', order.id, nil).and_return(FakeMessageDelivery.new)
        subject.reserve!
        expect(good.reload.quantity).to eq(-1)
      end
    end

    context 'infinite reserve' do
      before do
        good.update_column :quantity, nil
      end

      it 'must not change quantity' do
        expect(good.quantity).to eq nil
        subject.reserve!
        expect(good.reload.quantity).to eq nil
      end
    end
  end

  describe '#local_unreserve' do
    context 'negative unreserve' do
      it 'must change to 0' do
        subject.reserve!
        expect(good.reload.quantity).to eq(0)
        subject.unreserve!
        expect(good.reload.quantity).to eq(1)
      end
    end

    context 'infinite unreserve' do
      before do
        good.update_column :quantity, nil
      end

      it 'must not change quantity' do
        expect(good.quantity).to eq nil
        subject.unreserve!
        expect(good.quantity).to eq nil
      end
    end
  end
end
