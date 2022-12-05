require 'rails_helper'

RSpec.describe Operator::IntegrationsController, type: :controller do
  include OperatorControllerSupport

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end
end
