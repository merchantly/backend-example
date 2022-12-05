require 'rails_helper'

RSpec.describe Category, type: :model do
  include CurrentVendor
  let!(:vendor) { create :vendor }

  before do
    set_current_vendor vendor
  end

  describe '#linked?' do
    let(:category) { create :category, ms_uuid: '123', vendor: vendor }

    describe 'включена синхронизация категорий' do
      before do
        allow(vendor).to receive(:categories_linked?).and_return true
      end

      it { expect(category).to be_stock_linked }
      it { expect(category).to be_linked }
    end

    describe 'ВЫКЛЮЧЕНА синхронизация категорий' do
      before do
        allow(vendor).to receive(:categories_linked?).and_return false
      end

      it { expect(category).to be_stock_linked }
      it { expect(category).not_to be_linked }
    end
  end

  context 'методы класса' do
    subject! { described_class.find_or_create_by_name vendor, category_name, parent }

    let!(:parent) { create :category, vendor: vendor }

    context 'без родителя' do
      describe 'категории нет' do
        let(:category_name) { generate :category_name }

        it 'должен создать категорию' do
          expect(subject).to be_a described_class
        end
      end

      describe 'категория уже есть' do
        let(:category)      { create :category, vendor: vendor, parent: parent }
        let(:category_name) { category.name }

        it 'нашел категорию' do
          expect(subject).to eq category
        end
      end
    end

    context 'с родителем' do
      let(:parent) { create :category }
      let(:category_name) { [parent.name, generate(:category_name)].join '/' }

      it 'должен создать категорию' do
        expect(subject.parent).to eq parent
      end
    end
  end
end
