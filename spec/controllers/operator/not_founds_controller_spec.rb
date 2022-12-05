require 'rails_helper'

RSpec.describe Operator::NotFoundsController, type: :controller do
  include OperatorControllerSupport

  let!(:history_path) { create :history_path, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(HistoryPath).to receive :update
      patch :update, params: { id: history_path.id, response_state: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(HistoryPath).to receive :destroy
      delete :destroy, params: { id: history_path.id }
      expect(response.status).to eq 302
    end
  end
end
