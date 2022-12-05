require 'rails_helper'

describe RegisteredVendorFactory do
  subject do
    described_class.new(
      vendor_registration_form: registration_form,
      user_history: history,
      remote_ip: '1.1.1.1',
      current_operator: current_operator,
      locale: 'en'
    )
  end

  let(:demo_vendor) { create :vendor, :payments_and_deliveries }
  let(:init_utm) { build :utm_entity }
  let(:last_utm) { build :utm_entity }
  let(:init_referer) { 'aaa' }
  let(:last_referer) { 'bbb' }
  let(:history) do
    OpenStruct.new init_utm: init_utm, last_utm: last_utm, init_referer: init_referer, last_referer: last_referer
  end
  let!(:vendor_template) { create :vendor_template, vendor: demo_vendor }
  let!(:vendor_template2) { create :vendor_template }
  let(:current_operator) { nil }

  before :all do
    Vendor.delete_all
  end

  describe 'обычная регистрация' do
    let(:registration_form) { build :vendor_registration_form, vendor_template_id: vendor_template.id }

    it do
      expect { subject.build }.to change(Vendor, :count)
    end

    context 'уже есть предсозданный магазин' do
      let!(:vendor_precreated) { vendor_template.precreate! }

      it 'creates vendor with all stuff' do
        # при реигстрации количество мгазинов не изменяется, так как идет использование
        # уже предсозданных
        expect { subject.build }.not_to change(Vendor, :count)
      end

      it do
        expect(subject.build).to eq Operator.last
      end

      it do
        expect(vendor_precreated.is_pre_create).to be_truthy
        subject.build
        expect(vendor_precreated.reload.is_pre_create).to be_falsey
      end

      it do
        subject.build
        vendor = subject.vendor
        expect(vendor.init_utm).to eq init_utm
        expect(vendor.last_utm).to eq last_utm
        expect(vendor.init_referer).to eq init_referer
        expect(vendor.last_referer).to eq last_referer
        expect(vendor.vendor_payments.first.payment_agent_type).to eq 'OrderPaymentDirect'
        expect(vendor.vendor_payments.count).to eq 1
        expect(vendor.vendor_payments.last.vendor_deliveries).to eq vendor.vendor_deliveries
        expect(vendor.vendor_deliveries.last.vendor_payments).to eq vendor.vendor_payments
        expect(vendor.workflow_states.count).to eq 4
        expect(vendor.order_operator_filters.count).to eq 4
        expect(vendor.order_operator_filters.last.color_hex).to eq vendor.workflow_states.last.color_hex
        expect(vendor.vendor_deliveries.count).to eq 1
        expect(vendor.categories.count).to eq(Settings.welcome_category_required ? 1 : 0)
        expect(Operator.count).to eq 1
        expect(vendor.operators.count).to eq 1
        expect(vendor.support_email).to eq registration_form.email
        expect(vendor.is_published).to be_falsey
        expect(vendor.registration_at).not_to be_nil

        operator = vendor.operators.first
        expect(operator.name).to eq registration_form.operator_name
      end
    end

    context 'default operator name' do
      before { registration_form.operator_name = '' }

      it do
        subject.build
        expect(subject.operator.name).to eq(
          I18n.t('services.vendor_registration.operator_name',
                 vendor: subject.vendor.name)
        )
      end
    end
  end

  describe 'попытка зарегистрировать зарезревированный поддомен' do
    let(:vendor_name) { 'test' }
    let(:registration_form) { build :vendor_registration_form, vendor_name: vendor_name, vendor_template_id: vendor_template.id }

    it 'поддомент переименован в +N' do
      expect { subject.build }.to change(Vendor, :count)
    end
  end

  describe 'попытка зарегистрировать уже существующего вендора' do
    let(:vendor_name) { 'subdomain' }
    let(:registration_form) { build :vendor_registration_form, vendor_name: vendor_name }
    let(:vendor) { create :vendor, subdomain: vendor_name, name: vendor_name }

    before do
      vendor
    end

    context do
      let(:registration_form) { build :vendor_registration_form, vendor_name: vendor_name, vendor_template_id: vendor_template.id }

      it 'creates vendor with all stuff' do
        expect(subject.build).to be_persisted
        expect(subject.vendor).to be_persisted
        expect(subject.vendor).not_to eq vendor
        expect(subject.vendor.name).to eq vendor_name
      end
    end
  end

  describe 'регистрация от авторизованного оператор' do
    let(:vendor) { create :vendor, :with_operator }
    let(:current_operator) { vendor.operators.first }
    let(:registration_form) { build :vendor_registration_form, vendor_template_id: vendor_template.id }

    it 'форма не должна валидироваться' do
      expect(subject.build).to be_persisted
      expect(subject.vendor).to be_persisted
      expect(subject.vendor).not_to eq vendor
      expect(subject.operator).to eq current_operator
    end
  end
end
