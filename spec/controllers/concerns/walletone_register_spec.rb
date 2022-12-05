require 'rails_helper'

RSpec.describe Operator::WalletoneController, type: :controller do
  include OperatorControllerSupport
  let!(:branch_category) { create :branch_category }
  let(:phone) { '+79033891228' }

  let(:form) do
    W1::RegistrationForm.new(
      phone: phone,
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

  describe 'POST create with walletone exception' do
    subject { post :create, params: { w1_registration_form: form.to_hash } }

    it 'renders new form' do
      allow_any_instance_of(W1::RegistrationService).to(
        receive(:register!).and_raise(W1::RegistrationService::EmailExistsError.new(400, {}, ''))
      )
      expect(subject).to render_template(:new)
    end
  end
end
