require 'rails_helper'

RSpec.describe VendorLocator, type: :model do
  let!(:vendor) { create :vendor, :with_package_category }
  let!(:product) { create :product, vendor: vendor }

  describe '#locate' do
    subject { vendor.locate entity.to_global_id.to_param }

    let(:wrong_product) { create :product }

    context 'right' do
      let!(:entity) { product }

      it { expect(subject).to eq entity }
    end

    context 'wrong' do
      let!(:entity) { wrong_product }

      it { expect { subject }.to raise_error VendorLocator::Error }
    end
  end

  describe '#locate_good' do
    subject { vendor.locate_good entity.to_global_id.to_param }

    let!(:not_good) { create :category, vendor: vendor }

    context 'right' do
      let!(:entity) { product }

      it { expect(subject).to eq entity }
    end

    context 'wrong' do
      let!(:entity) { not_good }

      it { expect { subject }.to raise_error VendorLocator::Error }
    end
  end

  describe '#locate_good' do
    subject { vendor.locate_package entity.to_global_id.to_param }

    let!(:package) { create :product, vendor: vendor, category_ids: [vendor.package_category_id] }

    context 'right' do
      let!(:entity) { package }

      it { expect(subject).to eq entity }
    end

    context 'wrong' do
      let!(:entity) { product }

      it { expect { subject }.to raise_error VendorLocator::Error }
    end
  end
end
