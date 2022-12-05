require 'rails_helper'

RSpec.describe System::VendorsController, type: :controller do
  let!(:vendor_template) { create :vendor_template, :with_precreated_vendors }
  let!(:vendor_template2) { create :vendor_template }

  describe '#new' do
    it 'первый подход генерирует форму' do
      get :new
      expect(response).to render_template :new
      expect(response.status).to eq(200)
    end
  end

  describe '#create' do
    let(:registration_form) { { vendor_name: 'shopik', phone: '+79033891228', operator_name: 'Вася', email: 'danil@ggg.ru' } }

    before do
      allow_any_instance_of(VendorCss).to receive :save
    end

    it 'есть есть только форма, то выдаем выбор шаблона' do
      post :create, params: { vendor_registration_form: registration_form }
      expect(response).to render_template 'system/vendors/choice_template'
      expect(response.status).to eq(200)
    end

    it do
      post :create, params: { vendor_registration_form: registration_form.merge(vendor_template_id: vendor_template.id, is_agree: true) }
      expect(response.status).to redirect_to operator_registration_success_url(host: vendor_template.vendors.take.operator_host)
    end

    context 'такой email уже есть' do
      let(:email) { 'test@kiiiosk.store' }
      let(:registration_form) { { vendor_name: 'shopik', phone: '+79033891228', operator_name: 'Вася', email: email } }
      let(:vendor) { create :vendor }
      let(:operator) { create :operator, email: email }
      let!(:member) { create :member, operator: operator, vendor: vendor }

      it 'снова показываем форму контактов' do
        post :create, params: { vendor_registration_form: registration_form.merge(vendor_template_id: vendor_template.id, is_agree: true) }
        expect(response).to render_template 'system/vendors/set_contacts'
        expect(response.status).to eq(200)
      end
    end
  end
end
