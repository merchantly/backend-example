require 'rails_helper'

RSpec.describe Operator::SliderImagesController, type: :controller do
  include OperatorControllerSupport

  let!(:slider_image) { create :slider_image, vendor: vendor }

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
    it 'redirects' do
      get :show, params: { id: slider_image.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: slider_image.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.slider_images).to receive :create!
      post :create, params: { slider_image: slider_image.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(SliderImage).to receive :update!
      patch :update, params: { id: slider_image.id, slider_image: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end
end
