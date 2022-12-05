require 'rails_helper'

RSpec.describe ProductImage, type: :model do
  let(:vendor)        { create :vendor }
  let(:product_image) { create :product_image, vendor: vendor }
  let(:product)       { create :product, vendor: vendor, image_ids: [product_image.id] }

  describe 'когда картинку удалят она автоматом удаляется из товара' do
    before do
      product_image.destroy!
    end

    it { expect(product.reload.image_ids).to be_empty }
  end
end
