require 'rails_helper'

describe ProductOrderingService do
  subject { described_class.new product }

  let!(:product) { create :product, :ordering }

  it { expect(subject.state).to be_a ProductOrderingService::State }

  describe '#state' do
    subject { described_class.new(product).state }

    it { expect(subject.is_ordering).to be_truthy }
    it { expect(subject.errors).to be_empty }
  end

  describe 'Товар с дефолтным вариантом и другими вариантами в архиве' do
    subject { described_class.new(product).is_ordering }

    let!(:product) { create :product }
    let!(:product_item1) { create :product_item, product: product, archived_at: Time.zone.now }
    let!(:product_item2) { create :product_item, :ordering, product: product, is_default: true }

    it { expect(subject).to be_truthy }
  end

  describe '#is_ordering' do
    subject { described_class.new(product).is_ordering }

    let!(:vendor) { create :vendor, sellable_infinity: sellable_infinity }
    let!(:product) { build :product, :ordering, vendor: vendor, quantity: quantity }

    context 'продаваемая бесконечность' do
      let(:sellable_infinity) { true }

      context do
        let(:quantity) { 0 }

        it { expect(subject).to be false }
      end

      context do
        let(:quantity) { nil }

        it { expect(subject).to be true }
      end

      context do
        let(:quantity) { 1 }

        it { expect(subject).to be true }
      end
    end

    context 'nil как пусто' do
      let(:sellable_infinity) { false }

      context do
        let(:quantity) { 0 }

        it { expect(subject).to be false }
      end

      context do
        let(:quantity) { nil }

        it { expect(subject).to be false }
      end

      context do
        let(:quantity) { 1 }

        it { expect(subject).to be true }
      end
    end
  end
end
