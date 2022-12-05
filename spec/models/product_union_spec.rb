require 'rails_helper'

RSpec.describe ProductUnion, type: :model do
  describe 'с товарами' do
    subject { create :product_union, :products }

    it { expect(subject).not_to be_remove_from_index }
  end

  describe 'без товаров' do
    subject { create :product_union }

    it { expect(subject).to be_a described_class }
    it { expect(subject).to be_remove_from_index }
    it { expect(Product.find(subject.id)).to be_a described_class }
  end

  describe 'когда товары все в архиве' do
    subject { create :product_union, :products }

    it { expect(subject).to be_a described_class }
    it { expect(subject).to be_alive }

    context 'товары в архив' do
      before do
        subject.products.find_each(&:archive!)
      end

      it { expect(subject).to be_remove_from_index }
      it { expect(subject).to be_archived }
    end
  end
end
