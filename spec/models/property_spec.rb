require 'rails_helper'

RSpec.describe Property, type: :model do
  let(:property) { build :property }

  describe 'create w/' do
    context 'Property type' do
      it 'does not create property' do
        expect do
          property.save!
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'PropertyString type' do
      let(:property) { build :property, type: 'PropertyString' }

      it 'creates property' do
        expect do
          property.save!
        end.not_to raise_error
      end
    end
  end

  describe '#destroy' do
    let!(:vendor) { create :vendor }
    let(:property) { create :property_string, vendor: vendor }
    let(:property1) { create :property_string, vendor: vendor }
    let!(:product) { create :product, vendor: vendor, data: { property.id.to_s => '123', property1.id => 'asdf' } }

    before { property.destroy }

    it 'deletes self from product.data' do
      expect(product.reload.data).to eq(property1.id.to_s => 'asdf')
    end
  end
end
