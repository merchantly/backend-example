require 'rails_helper'

RSpec.describe Slugable, type: :model do
  subject { product }

  let(:product) { create :product }

  it do
    expect(subject.slug).to be_blank
  end

  describe '#public_url' do
    let(:attributes) { { page: 2, per_page: 100 } }

    context 'w/out params' do
      it 'must not contain params' do
        expect(subject.public_url).not_to match(/#{attributes.to_query}/)
      end
    end

    context 'w/ params' do
      before do
        subject.update slug_attributes: { path: '123' }
      end

      it 'must contain params' do
        expect(subject.public_url(attributes)).to match(/#{attributes.to_query}/)
      end
    end
  end

  context do
    let(:slug_attributes) { { path: path } }

    before do
      subject.update slug_attributes: slug_attributes
    end

    context do
      let(:path) { '123' }

      it do
        expect(subject.slug).to be_persisted

        # Устанавливаем снова тоже самое
        subject.update slug_attributes: slug_attributes
        expect(subject.slug).to be_persisted

        # Удаляем slug
        subject.update slug_attributes: { path: '' }
        expect(subject.slug).not_to be_persisted

        subject.save!

        expect(subject.reload.slug).to be_blank
      end
    end

    context do
      let(:path) { '' }

      it do
        expect(subject.slug).not_to be_persisted
      end
    end
  end
end
