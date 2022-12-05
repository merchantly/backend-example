require 'rails_helper'

RSpec.describe Operator::MembersController, type: :controller do
  include OperatorControllerSupport

  let(:member) { create :member, vendor: vendor }
  let(:role) { vendor.roles.find_by(key: :manager) }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe 'DELETE destroy' do
    before { member.update_attribute :role, role }

    it 'redirects' do
      expect_any_instance_of(Member).to receive :destroy!
      delete :destroy, params: { id: member.id }
      expect(response.status).to eq 302
    end
  end
end
