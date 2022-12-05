require 'rails_helper'

RSpec.describe System::SessionsController, type: :controller do
  let!(:invite)  { create :invite }
  let(:vendor)   { invite.vendor }

  let(:password) { 'password' }
  let(:login)    { operator.email }

  let!(:operator) { create :operator, password: password }

  context 'background' do
    it do
      expect(vendor.operators).not_to include operator
    end
  end

  describe '#create' do
    let(:form) { { login: login, password: password } }

    context 'no invite' do
      context 'operator has many vendors' do
        let(:vendor2) { create :vendor }
        let(:vendor3) { create :vendor }
        let!(:member) { create :member, vendor: vendor2, operator: operator }
        let!(:member2) { create :member, vendor: vendor3, operator: operator }

        it do
          post :create, params: { operator_login_form: form }

          expect(response).to be_redirection
          expect(response.redirect_url).to eq 'http://app.test.host/operator_vendors'
        end
      end

      context 'operator has one vendor' do
        let!(:operator) { create :operator, :has_vendor, password: password }

        it do
          post :create, params: { operator_login_form: form }

          expect(response).to be_redirection
          expect(response.redirect_url).to eq operator.vendors.first.operator_url
        end
      end
    end

    context 'invite' do
      let(:form) { { login: login, password: password } }

      context 'operator has many vendors' do
        let(:vendor2) { create :vendor }
        let(:vendor3) { create :vendor }
        let!(:member) { create :member, vendor: vendor2, operator: operator }
        let!(:member2) { create :member, vendor: vendor3, operator: operator }

        it do
          post :create, params: { operator_login_form: form, invite_key: invite.key }

          expect(response).to be_redirection
          expect(response.redirect_url).to eq 'http://app.test.host/operator_vendors'
          expect(vendor.operators).to include operator
        end
      end

      context 'operator has one vendor' do
        it do
          post :create, params: { operator_login_form: form, invite_key: invite.key }

          expect(response).to be_redirection
          expect(response.redirect_url).to eq vendor.operator_url
          expect(vendor.operators).to include operator
        end
      end
    end

    context 'phone confirmation' do
      let(:login) { operator.phone }
      let(:form)  { { login: login, password: operator.pin_code } }

      it do
        expect_any_instance_of(Operator).to receive(:confirm_phone!)
        post :create, params: { operator_login_form: form }
        expect(response).to be_redirection
      end
    end
  end
end
