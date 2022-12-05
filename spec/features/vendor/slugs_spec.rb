require 'rails_helper'

RSpec.describe 'Slug-и и локаль', type: :feature do
  let!(:default_locale) { 'ru' }
  let!(:vendor) { create :vendor, available_locales: %w[ru en] }

  before do
    Capybara.app_host = vendor.home_url
    I18n.locale = :ru
  end

  context 'главная' do
    it 'не указанный язык пустой путь' do
      visit ''
      expect(page).to have_current_path('/')
    end

    it 'не указанный язык /' do
      visit '/'
      expect(page).to have_current_path('/')
    end

    it 'дефолтный язык тоже уставляем' do
      visit '/ru'
      expect(page).to have_current_path('/ru')
    end

    it 'указан второй язык' do
      visit '/en'
      expect(page).to have_current_path('/en')
    end
  end

  context 'товар' do
    describe 'slug указан' do
      let!(:product)  { create :product, :ordering, :slug, vendor: vendor }
      let!(:path) { product.public_path } # Берем путь заранее, чтобы на него не влияла локаль

      it 'не указанный язык' do
        visit product.public_path
        expect(page.status_code).to eq 200
        expect(page.title).to start_with product.title
        expect(page).to have_current_path(path)
      end

      it 'указанный язык по-умолчанию, редиректнули' do
        visit "/ru#{product.public_path}"
        expect(page.title).to start_with product.title
        expect(page).to have_current_path(path)
      end

      it 'указан второй язык' do
        visit "/en#{product.public_path}"
        expect(page.status_code).to eq 200
        expect(page.title).to start_with product.title
        expect(page).to have_current_path("/en#{path}")
      end
    end

    describe 'slug НЕ указан' do
      let(:product) { create :product, :ordering, vendor: vendor }
      let!(:path) { product.public_path } # Берем путь заранее, чтобы на него не влияла локаль

      it 'не указанный язык' do
        visit product.public_path
        expect(page.status_code).to eq 200
        expect(page.title).to start_with product.title
        expect(page).to have_current_path(path)
      end

      it 'указанный язык по-умолчанию' do
        visit "/ru#{product.public_path}"
        expect(page.title).to start_with product.title
        expect(page).to have_current_path(path)
      end

      it 'указан второй язык' do
        visit "/en#{product.public_path}"
        expect(page.status_code).to eq 200
        expect(page.title).to start_with product.title
        expect(page).to have_current_path("/en#{path}")
      end
    end
  end
end
