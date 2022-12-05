require 'rails_helper'

RSpec.describe ProductTags, type: :model do
  let(:vendor) { create :vendor }
  let(:product) { create :product, vendor: vendor }

  describe '#add_tag' do
    before do
      product.add_tag 'test'
    end

    it do
      expect(product.tags_list).to eq 'test'
    end

    context do
      before do
        product.tags_list = 'test, AAA'
      end

      it do
        expect(product.tags_list).to eq 'test,AAA'

        product.tags_list = ''
        expect(product.tags_list).to eq ''
        expect(product.tags.reload).to be_empty
      end
    end
  end
end
