require 'rails_helper'

describe VendorTranslationsService do
  subject { described_class.new vendor }

  let!(:vendor) { create :vendor }
  let(:locale) { :ru }

  it 'контролька' do
    expect(subject.all_translations[locale][:order][:placeholders]).to be_a Hash
  end

  context do
    before do
      vendor.translations.create! key: key, value: value, locale: locale
    end

    context 'dome' do
      let(:key)   { 'foo.bar' }
      let(:value) { 'value' }

      it do
        expect(subject.all_translations[locale][:foo]).to eq(bar: value)
      end
    end

    context 'order' do
      let(:key)   { 'order.some' }
      let(:value) { 'value' }

      it do
        expect(subject.all_translations[locale][:order][:some]).to eq value
        expect(subject.all_translations[locale][:order][:placeholders]).to be_a Hash
      end
    end
  end
end
