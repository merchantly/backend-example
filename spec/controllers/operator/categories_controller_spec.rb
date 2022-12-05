require 'rails_helper'

RSpec.describe Operator::CategoriesController, type: :controller do
  include OperatorControllerSupport

  let!(:category) { create :category, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show, params: { id: category.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: category.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { category: category.attributes.merge(parent_id: category.parent_id, custom_title_ru: 'test') }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(Category).to receive :update!
      patch :update, params: { id: category.id, category: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH special_categories' do
    it 'redirects' do
      expect_any_instance_of(Vendor).to receive :update!
      post :special_categories, params: { vendor: { welcome_category_id: 1 } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE archive' do
    it 'redirects' do
      expect_any_instance_of(Category).to receive :archive!
      delete :archive, params: { id: category.id }
      expect(response.status).to eq 302
    end
  end

  describe 'POST restore' do
    it 'redirects' do
      expect_any_instance_of(Category).to receive :restore!
      post :restore, params: { id: category.id }
      expect(response.status).to eq 302
    end
  end
end
