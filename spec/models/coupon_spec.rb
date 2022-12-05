require 'rails_helper'

RSpec.describe Coupon, type: :model do
  subject { coupon }

  let!(:discount) { 25 }
  let!(:discount_type) { :percent }
  let!(:coupon) { create :coupon_single, discount: discount, discount_type: discount_type, use_count: 1, used_count: 0 }

  specify do
    expect(subject).to be_persisted
    expect(subject).to be_alive
    expect(subject).not_to be_expired
    expect(subject.used_count).to eq 0
  end

  describe 'reusable coupon' do
    let(:coupon) { create :coupon_single, discount: discount, discount_type: discount_type, use_count: nil, used_count: 0 }

    it do
      expect(subject.expired?).to eq false
    end
  end

  describe '#call!' do
    context 'regular' do
      before { coupon.call! items_count: 1, is_first_client_order: false, is_address_used: false, total_price: 123 }

      specify do
        expect(coupon.used_count).to eq 1
        expect(coupon).to be_archived
        expect(coupon).to be_expired
      end
    end

    context 'expires_at < Time.zone.now' do
      before { coupon.update_columns expires_at: 1.second.ago }

      it 'must be expired' do
        expect { coupon.call! items_count: 1, is_first_client_order: false, is_address_used: false, total_price: 123 }.to raise_error Coupon::Expired
      end
    end

    context 'expires_at >= Time.zone.now' do
      before { coupon.update_columns expires_at: 1.minute.from_now }

      it 'must not be expired' do
        expect { coupon.call!  items_count: 1, is_first_client_order: false, is_address_used: false, total_price: 123 }.not_to raise_error
      end
    end
  end
end
