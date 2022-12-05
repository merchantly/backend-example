require 'rails_helper'

RSpec.describe ProductImages, type: :model do
  let(:vendor) { create :vendor }

  context 'создаем товар с предзагруженной картинкой' do
    let(:product_image) { create :product_image, vendor: vendor }
    let(:product)       { create :product, vendor: vendor, image_ids: [product_image.id] }

    it { expect(product.image_ids).to eq [product_image.id] }
    it { expect(product.images).to eq [product_image] }
    it { expect(product).to eq product_image.reload.product }
  end

  context 'добавили в cущестующий товар свежую картинку' do
    let(:product) { create :product, vendor: vendor }
    let(:product_image) { create :product_image, vendor: vendor }

    before do
      product.image_ids = [product_image.id]
      product.save!
    end

    it { expect(product.image_ids).to have(1).item }
    it { expect(product.images).to have(1).item }
    it { expect(product.images.first).to eq product_image }
    it { expect(product_image.reload.product_id).to eq product.id }
  end
end
