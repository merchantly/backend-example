require 'rails_helper'

RSpec.describe VendorProductsFilterBuilder, type: :model do
  let(:query)   { 'asdasdsaad' }
  let!(:params) { ActiveSupport::HashWithIndifferentAccess.new query: query }

  describe '#build_from_params' do
    subject do
      VendorProductsFilter.build_from_params params
    end

    it do
      expect(subject.query).to eq query
    end
  end

  describe '#public_build_from_params' do
    subject do
      VendorProductsFilter.public_build_from_params params
    end

    it do
      expect(subject.to_param).to eq params.symbolize_keys
    end
  end

  describe '#custom_attributes' do
    context 'standalone value' do
      subject do
        VendorProductsFilter.send :custom_attributes, params
      end

      let!(:params) { ActiveSupport::HashWithIndifferentAccess.new attr_1: 1 }

      it do
        expect(subject).to eq('attr_1' => [1])
      end
    end

    context 'multiple values' do
      subject do
        VendorProductsFilter.send :custom_attributes, params
      end

      let(:values) { %w[on off] }
      let!(:params) { ActiveSupport::HashWithIndifferentAccess.new attr_1: values }

      it do
        expect(subject).to eq('attr_1' => values)
      end
    end
  end

  describe '#price_range' do
    subject do
      VendorProductsFilter.send :price_range, params
    end

    let!(:params) { ActiveSupport::HashWithIndifferentAccess.new price: { from: 12, to: 24 } }

    it do
      expect(subject).to eq 1200..2400
    end
  end
end
