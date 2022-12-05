require 'rails_helper'

RSpec.describe Operator::FaviconsController, type: :controller do
  include OperatorControllerSupport

  let!(:vendor) { create :vendor, id: 1 }
  let(:favicon_file) { create :favicon_file, vendor: vendor }
  let(:image) { fixture_file_upload('favicon.ico') }
  let(:logo) { fixture_file_upload('logo.png') }
  let(:favicon_16) { fixture_file_upload('favicon-16x16.png') }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'returns http success' do
      post :create, params: { theme: { favicon_file: image } }
      expect(response.status).to eq 200
    end
  end

  describe 'POST upload_logo' do
    it 'returns http success' do
      post :upload_logo, params: { theme: { logo_file: logo } }
      expect(response.status).to eq 200
    end
  end

  describe 'DELETE destroy' do
    before { post :create, params: { theme: { favicon_file: favicon_16 } } }

    it 'redirects' do
      delete :destroy, params: { id: :favicon, format: :ico }
      expect(response).to redirect_to operator_settings_favicons_path

      delete :destroy, params: { id: 'favicon-16x16', format: :png }
      expect(response).to redirect_to operator_settings_favicons_path
    end
  end
end
