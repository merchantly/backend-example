require 'rails_helper'

RSpec.describe System::OperatorsController, type: :controller do
  describe '#new' do
    let!(:invite) { create :invite }

    it 'без приглашения' do
      get :new
      expect(response).to render_template :new
      expect(response.status).to eq(200)
    end

    it 'с действующим приглашением' do
      get :new, params: { invite_key: invite.key }

      expect(response).to render_template :invite
      expect(response.status).to eq(200)
    end

    it 'с просроченным приглашением' do
      get :new, params: { invite_key: 'broken' }
      expect(response).to render_template :new
      expect(response.status).to eq(200)
    end
  end

  describe '#create' do
    context 'без приглашения' do
      let(:operator_params) { { name: 'Вася', email: 'danil@ggg.ru' } }

      it do
        get :create, params: { operator: operator_params }
        expect(response.status).to redirect_to system_profile_url
        expect(Operator.find_by(email: operator_params[:email])).to be_present
      end
    end

    context 'с приглашением и с другим емайлом' do
      let(:invite) { create :invite, email: generate(:email), phone: nil }
      let(:email)  { generate :email }
      let(:operator_params) { { name: 'Вася', email: email } }

      it 'убеждаемся что у invite-а другой email' do
        expect(invite.email).not_to eq email
      end

      it do
        get :create, params: { operator: operator_params, invite_key: invite.key }
        expect(response.status).to redirect_to invite.vendor.operator_url
        expect(Operator.find_by(email: email)).to be_persisted
      end
    end

    context 'с ошибками' do
      let(:invite) { create :invite }
      let(:operator_params) { { name: 'Вася' } }

      it do
        get :create, params: { operator: operator_params }
        expect(response).to render_template :new
      end
    end
  end

  describe '#confirm_email' do
    let!(:operator) { create :operator, email: 'some@email.ru' }
    # before { operator.send :require_email_confirmation }

    it 'must redirect' do
      expect_any_instance_of(Operator).to receive(:confirm_email!)
      get :confirm_email, params: { token: operator.email_confirm_token }
      expect(response.status).to eq 302
    end
  end
end
