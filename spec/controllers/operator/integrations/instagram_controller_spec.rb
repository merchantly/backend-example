require 'rails_helper'

RSpec.describe Operator::Integrations::InstagramController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end
end
