require 'rails_helper'

RSpec.describe ContentPage, type: :model do
  include CurrentVendor
  let!(:vendor) { create :vendor }

  before do
    set_current_vendor vendor
  end

  context 'translates out' do
    let(:content_page) do
      create :content_page, title_ru: 'title_ru', title_en: 'title_en', vendor_id: vendor.id
    end

    describe 'default locale ru' do
      before do
        HstoreTranslate.locale = :ru
        HstoreTranslate.available_locales = current_vendor.available_locales
      end

      it { expect(content_page.title).to eq 'title_ru' }
    end

    describe 'default locale en' do
      before do
        HstoreTranslate.locale = :en
        HstoreTranslate.available_locales = current_vendor.available_locales
      end

      it { expect(content_page.title).to eq 'title_en' }
    end
  end

  context 'translates validation' do
    let(:content_page) do
      described_class.new title_ru: 'title_ru', title_en: '', vendor_id: vendor.id
    end

    describe 'default locale ru' do
      before do
        HstoreTranslate.locale = :ru
        HstoreTranslate.available_locales = [:ru]
      end

      it { expect(content_page).to be_valid }
    end

    describe 'default locale en' do
      before do
        vendor.default_locale = :en
        HstoreTranslate.locale = :en
        HstoreTranslate.available_locales = [:en]
      end

      it { expect(content_page).to be_valid }
    end
  end
end
