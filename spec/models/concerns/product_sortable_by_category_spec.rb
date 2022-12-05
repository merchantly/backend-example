require 'rails_helper'

RSpec.describe ProductSortableByCategory, type: :model do
  let!(:vendor) { create :vendor }
  let!(:category) { create :category, vendor: vendor }

  let(:category_id) { category.id }
  let!(:product1) { create :product, vendor: vendor, categories: [category] }
  let!(:product2) { create :product, vendor: vendor, categories: [category] }
  let!(:product3) { create :product, vendor: vendor, categories: [category] }

  describe '#position_in_category' do
    it 'соблюден порядок товаров' do
      pos1 = product1.ranked_position_in_category(category_id)
      pos2 = product2.ranked_position_in_category(category_id)
      pos3 = product3.ranked_position_in_category(category_id)

      expect(pos1).to be < pos2
      expect(pos2).to be < pos3
    end

    it 'соблюден порядок товаров' do
      pos1 = product1.position_in_category(category_id)
      pos2 = product2.position_in_category(category_id)
      pos3 = product3.position_in_category(category_id)

      expect(pos1).to eq 0
      expect(pos2).to eq 1
      expect(pos3).to eq 2
    end
  end

  describe 'двигаем наверх' do
    it do
      pos2 = product2.position_in_category(category_id)
      product3.update_position_in_category category_id, pos2 - 1

      pos2 = product2.reload.ranked_position_in_category(category_id)
      pos3 = product3.reload.ranked_position_in_category(category_id)

      expect(pos2 > pos3).to be_truthy
    end
  end

  describe 'двигаем вниз' do
    it do
      product2.ranked_position_in_category(category_id)
      product1.update_position_in_category category_id, 1
      product1.save

      pos2 = product2.reload.ranked_position_in_category(category_id)
      pos1 = product1.reload.ranked_position_in_category(category_id)

      expect(pos1).to be > pos2
    end
  end

  context 'Новая категория, автоматически добавляем позицию' do
    let!(:category2) { create :category, vendor: vendor }
    let(:category_id) { category2.id }

    it 'товара нет в этой категории и его позиция nil' do
      expect(product1.ranked_position_in_category(category_id)).to be nil
    end

    context 'Добавили товару категорию' do
      before do
        product1.update_attribute :category_ids, [category_id]
      end

      it 'единственный товар в категории, у него позиция 0' do
        expect(product1.ranked_position_in_category(category_id)).to be 0
      end

      context 'добавили еще товар' do
        context 'vendor.default_product_position = last' do
          before do
            product2.vendor.update default_product_position: :last
            product2.update_attribute :category_ids, [category_id]
          end

          it 'последний товар' do
            expect(product2.position_in_category(category_id)).to be product1.position_in_category(category_id) + 1
          end
        end

        context 'vendor.default_product_position = first' do
          before do
            product2.vendor.update default_product_position: :first
            product2.update_attribute :category_ids, [category_id]
          end

          it 'первый товар' do
            expect(product2.position_in_category(category_id)).to be 0
          end
        end
      end
    end
  end

  context 'Товары без позиции получают позицию как только она появляется хотя-бы у одного' do
    let!(:product1) { create :product, vendor: vendor }
    let!(:product2) { create :product, vendor: vendor }

    before do
      Product.where(id: [product1.id, product2.id]).each do |pr|
        pr.update category_ids: [category.id]
      end
    end

    it 'контролька: товары в категории всегда имеют позицию' do
      expect(product1.position_in_category(category.id)).not_to be_nil
      expect(product2.position_in_category(category.id)).not_to be_nil
    end

    it 'у второго товара тоже появляется позиция' do
      product1.update_position_in_category! category.id, 1
      expect(product2.reload.ranked_position_in_category(category.id)).not_to be_nil
    end
  end
end
