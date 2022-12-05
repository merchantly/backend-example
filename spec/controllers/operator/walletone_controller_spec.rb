require 'rails_helper'

RSpec.describe Operator::WalletoneController, type: :controller do
  include OperatorControllerSupport
  let!(:branch_category) { create :branch_category }
  let(:phone) { '+79033891228' }

  let(:form) do
    W1::RegistrationForm.new(
      phone: phone,
      currency_id: 840,
      legal_form: 'personal',
      title: 'shop',
      first_name: 'name',
      middle_name: 'name',
      last_name: 'name',
      branch_category_id: branch_category.id,
      email: 'email@email.ru'
    )
  end

  before do
    vendor.vendor_walletone.update_columns phone: phone, phone_confirmed: phone, phone_confirmed_at: Time.zone.now
  end

  it 'контролька' do
    expect(form).to be_valid
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'returns http success' do
      expect_any_instance_of(W1::RegistrationService).to receive(:register!)
      post :create, params: { w1_registration_form: form.to_hash }
      expect(response.status).to eq 200
    end
  end
end
