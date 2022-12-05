require 'rails_helper'

RSpec.describe Operator::AssetImagesController, type: :controller do
  include OperatorControllerSupport

  let(:asset_image) { create :asset_image, vendor: vendor }
  let(:image) { fixture_file_upload('donut_1.png', 'image/png') }
  let(:image_attributes) { build(:asset_image, vendor: vendor).attributes.merge!(image: image) }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { asset_image: image_attributes }
      expect(response.status).to eq 200
    end
  end
end
