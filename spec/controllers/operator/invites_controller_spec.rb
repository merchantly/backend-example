require 'rails_helper'

RSpec.describe Operator::InvitesController, type: :controller do
  include OperatorControllerSupport

  let(:invite) { create :invite, vendor: vendor, operator_inviter: operator }

  describe 'POST create' do
    context 'Invite existent operator' do
      let!(:invited_operator) { create :operator }
      let(:invite_params) { { name: 'Operator Sasha', phone: invited_operator.phone, role: :manager } }

      it do
        post :create, params: { invite: invite_params }
        expect(response.status).to eq 302
      end
    end

    context 'Invite new operator' do
      context 'by phone' do
        let(:invite_params) { { phone: '+79033891228', role: :manager } }

        it 'redirects' do
          expect_any_instance_of(Invite).to receive :save!
          post :create, params: { invite: invite_params }
          expect(response.status).to eq 302
        end
      end

      context 'by email' do
        let(:invite_params) { { email: 'email@aaa.ru', role: :manager } }

        it 'redirects' do
          expect_any_instance_of(Invite).to receive :save!
          post :create, params: { invite: invite_params }
          expect(response.status).to eq 302
        end
      end
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(Invite).to receive :destroy!
      delete :destroy, params: { id: invite.id }
      expect(response.status).to eq 302
    end
  end
end
