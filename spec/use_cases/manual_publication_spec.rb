require 'rails_helper'

RSpec.describe 'пубилкация товара или карточки' do
  let(:vendor)       { create :vendor }
  let(:product)      { create :product, vendor: vendor, is_manual_published: true }

  it { expect(product.is_published).to be true }

  describe 'снимаем с публикации товар' do
    before { product.update_attribute :is_manual_published, false }

    it { expect(product.is_published).to be false }

    context 'возвращаем обратно' do
      before { product.update_attribute :is_manual_published, true }

      it { expect(product.is_published).to be true }
    end
  end
end
