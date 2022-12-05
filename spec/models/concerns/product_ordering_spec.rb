require 'rails_helper'

RSpec.describe ProductOrdering, type: :model do
  let!(:product) { create :product, quantity: 1, price: price, is_published: true }

  context 'товар без цены не пордается' do
    let(:price) { Money.new 100 }

    it { expect(product.is_ordering).to be true }
    it { expect(product.has_ordering_goods).to be true }

    describe 'без цены' do
      let(:price) { nil }

      it { expect(product.is_ordering).to be false }
      it { expect(product.has_ordering_goods).to be false }
    end
  end

  context 'свойства не сохраненного товара' do
    let!(:product) { build :product, quantity: 1, price: 123, is_manual_published: true }

    it { expect(product.is_ordering).to be true }
    it { expect(product.has_ordering_goods).to be true }
  end

  describe 'check sale period validation' do
    let(:current_time) { Time.zone.now }
    let!(:product) { build :product, quantity: 1, price: 123, ordering_start_at: sale_start, ordering_end_at: sale_end }

    context 'the end of the sale period before it begins' do
      let!(:sale_end) { current_time }
      let!(:sale_start) { sale_end + 1.day }

      it { expect(product.valid?).to be false }
    end

    context 'sale starts earlier than current time' do
      let!(:sale_start) { current_time - 1.minute }
      let!(:sale_end) { sale_start + 1.minute }

      it { expect(product.valid?).to be false }
    end

    context 'valid sale periods' do
      let!(:sale_start) { current_time }
      let!(:sale_end) { sale_start + 1.minute }

      it { expect(product.valid?).to be true }
    end

    context 'update attirube when sale period already set' do
      let!(:sale_start) { current_time - 2.days }
      let!(:sale_end) { sale_start + 1.day }
      before { product.save(validate: false) }

      it {
        product.price = 100
        expect(product.valid?).to be true
      }
    end
  end

  context 'quantity nil' do
    let!(:product) { build :product, quantity: nil, price: 123, is_manual_published: true }

    it { expect(product.quantity).to be_nil }

    it 'должен возвращать nil, чтобы можно было судить о продаваемой бесконечности' do
      expect(product.total_quantity).to be_nil
    end
  end
end
