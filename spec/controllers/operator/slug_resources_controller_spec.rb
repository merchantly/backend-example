require 'rails_helper'

RSpec.describe Operator::SlugResourcesController, type: :controller do
  include OperatorControllerSupport

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'DELETE destroy' do
    let!(:slug_resource) { create :slug_resource, vendor: vendor }

    it 'redirects' do
      expect_any_instance_of(SlugResource).to receive :destroy!
      delete :destroy, params: { id: slug_resource.id }
      expect(response.status).to eq 302
    end
  end
end
