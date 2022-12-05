require 'rails_helper'

describe OperatorAPI::Categories do
  include OperatorRequests

  describe 'DELETE /categories/:id' do
    it 'delete default category' do
      delete "/operator/api/v1/categories/#{vendor.welcome_category_id}"

      expect(response.status).to eq 403
    end
  end

  describe 'GET /categories/tree' do
    it 'get vendor info' do
      get '/operator/api/v1/categories/tree'

      assert response.ok?, 'результат ответа не OK'
    end
  end

  describe 'PUT /categories/:id' do
    let!(:category) { create :category, vendor: vendor }
    let!(:image) { fixture_file_upload('donut_1.png', 'image/png') }

    it do
      put "/operator/api/v1/categories/#{category.id}", params: { name: 'example', image: image }

      expect(response.status).to eq 200
    end
  end

  describe 'POST /categories' do
    it 'same title' do
      post '/operator/api/v1/categories', params: { name: 'example' }

      expect(response.status).to eq 201

      post '/operator/api/v1/categories', params: { name: 'example' }

      expect(response.status).to eq 422
    end

    it 'some title with field_locales' do
      post '/operator/api/v1/categories', params: { field_locales: 'en,ru', custom_title_en: 'Tests', custom_title_ru: 'Тест' }

      expect(response.status).to eq 201

      post '/operator/api/v1/categories', params: { field_locales: 'en,ru', custom_title_en: 'Tests', custom_title_ru: 'Тест' }

      expect(response.status).to eq 422
    end
  end

  describe 'PUT /categories/id/hide' do
    let!(:category) { create :category, vendor: vendor }
    let!(:product) { create :product, vendor: vendor, category: category }

    it 'hide not default category' do
      put "/operator/api/v1/categories/#{category.id}/hide"

      expect(response.status).to eq 200
      expect(category.reload.is_hidden?).to eq true
      expect(product.reload.is_hidden?).to eq true
    end

    it 'hide default category' do
      put "/operator/api/v1/categories/#{vendor.welcome_category_id}/hide"

      expect(response.status).to eq 403
      expect(vendor.welcome_category.reload.is_hidden?).to eq false
    end
  end

  describe 'PUT /categories/id/active' do
    let!(:category) { create :category, vendor: vendor, is_published: false }
    let!(:product) { create :product, vendor: vendor, category: category, is_manual_published: false }

    it do
      put "/operator/api/v1/categories/#{category.id}/active"

      expect(response.status).to eq 200
      expect(category.reload.is_active?).to eq true
      expect(product.reload.is_active?).to eq true
    end
  end

  describe 'GET /categories' do
    let!(:public_category) { create :category, vendor: vendor }
    let!(:hidden_category) { create :category, vendor: vendor, is_published: false }

    it 'get hidden' do
      get '/operator/api/v1/categories', params: { status: :hidden }

      expect(response.status).to eq 200
    end
  end
end
