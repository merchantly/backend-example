require 'rails_helper'

RSpec.describe System::PhoneConfirmationsController, type: :controller do
  include OperatorLoggedIn
  render_views

  let!(:operator) { create :operator }
  let!(:phone) { generate :phone }

  describe '#new' do
    it do
      get :new, params: { phone: phone, use_route: :new_system_phone_confirmation }
      expect(response).to be_ok
    end
  end

  describe '#new phone confirmed' do
    let(:phone_confirmation) { create :phone_confirmation, :confirmed, operator: operator }
    let(:backurl) { 'http://backurl' }

    it 'если телефон уже подтвержден кидаем на backurl' do
      get :new, params: { phone: phone_confirmation.phone, backurl: backurl, use_route: :new_system_phone_confirmation }
      expect(response).to be_redirection
      expect(response.redirect_url).to eq backurl + "?confirmed_phone=#{CGI.escape phone_confirmation.phone}"
    end
  end

  describe '#create' do
    it 'Мы не принимаем deliver_pin_code потому что оператор только что создан и ему уже отправляли pin_code' do
      expect_any_instance_of(PhoneConfirmation).not_to receive :deliver_pin_code!
      post :create, params: { phone: operator.phone, use_route: :system_phone_confirmation }
      expect(response).to be_ok
    end

    it do
      expect_any_instance_of(PhoneConfirmation).to receive(:deliver_pin_code)
      post :create, params: { phone: phone, use_route: :system_phone_confirmation }
      expect(response).to be_ok
    end
  end

  describe '#edit' do
    it do
      put :edit, params: { phone_confirmation_form: { phone: phone, pin_code: 123 }, use_route: :system_phone_confirmation }
      expect(response).to be_ok
    end
  end

  describe '#update' do
    let(:phone_confirmation) { create :phone_confirmation, :confirmed, operator: operator }

    it do
      put :update, params: { phone_confirmation_form: { phone: phone_confirmation.phone, pin_code: phone_confirmation.pin_code }, use_route: :system_phone_confirmation }
      expect(response).to be_redirection
      expect(phone_confirmation.reload).to be_is_confirmed
    end
  end
end
