require 'rails_helper'

RSpec.describe Operator::WorkflowStatesController, type: :controller do
  include OperatorControllerSupport

  let!(:workflow_state) { create :workflow_state, vendor: vendor }

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
      get :show, params: { id: workflow_state.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: workflow_state.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.workflow_states).to receive :create!
      post :create, params: { workflow_state: workflow_state.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(WorkflowState).to receive :update!
      patch :update, params: { id: workflow_state.id, workflow_state: { color_hex: '#fff' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(WorkflowState).to receive :destroy!
      delete :destroy, params: { id: workflow_state.id }
      expect(response.status).to eq 302
    end
  end
end
