require 'rails_helper'

RSpec.describe Operator::ActiveAdminCommentsController, type: :controller do
  include OperatorControllerSupport

  let!(:admin_comment) { create :admin_comment, author: vendor.operators.first }

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { active_admin_comment: admin_comment.attributes.except('id') }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(ActiveAdmin::Comment).to receive :destroy!
      delete :destroy, params: { id: admin_comment.id }
      expect(response.status).to eq 302
    end
  end
end
