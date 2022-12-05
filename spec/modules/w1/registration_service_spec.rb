require 'rails_helper'

describe W1::RegistrationService, :vcr do
  subject { described_class.new(vendor_walletone) }

  let(:vendor)           { create :vendor, :w1_not_approved }
  let(:vendor_walletone) { vendor.vendor_walletone }
  let!(:branch_category) { create :branch_category, CategoryId: 'Cars' }

  it 'контролька' do
    expect(vendor_walletone).not_to be_state_approved
  end

  context 'неполный профиль' do
    it do
      expect do
        subject.register!
      end.to raise_error(VendorWalletone::UncompleteProfile)
    end
  end

  describe 'полный профиль' do
    before do
      vendor_walletone.update!(
        title: 'Test company2',
        first_name: 'Иван',
        middle_name: 'Иванович',
        last_name: 'Иванов',
        email: 'asdf@asdf.com',
        currency_id: 840,
        phone: phone,
        phone_confirmed_at: Time.zone.now,
        phone_confirmed: phone,
        legal_form: 'personal',
        branch_category: branch_category
      )
    end

    context 'personal' do
      let(:phone) { '+79999999999' }

      before do
        stub_request(:post, W1::RegistrationService::API_URL).to_return(
          status: 200,
          body: '{"MerchantId":"1234","MerchantSignKey":"asdf","MerchantToken":"personal-token","OwnerUserId":"9999"}'
        )
      end

      it do
        expect do
          subject.register!
        end.not_to raise_error
      end

      it do
        subject.register!
        expect(vendor_walletone.merchant_id).to eq '1234'
        expect(vendor_walletone).to be_state_approved
      end

      describe 'ошибочки' do
        before do
          stub_request(:post, W1::RegistrationService::API_URL).to_return(
            status: 400,
            body: error
          )
        end

        context 'param format error' do
          let!(:error) { '{"Error":"PARAM_FORMAT_ERROR","ErrorDescription":"Incorrect MiddleName: A","Params":null}' }

          it do
            expect { subject.register! }.to raise_error W1::RegistrationService::ParamFormatError
          end
        end

        context 'email exists' do
          let!(:error) { '{"Error":"EMAIL_ALREADY_EXISTS","ErrorDescription":"Пользователь с адресом электронной почты «nurpeisov@gmail.com» уже существует"}' }

          it do
            expect { subject.register! }.to raise_error W1::RegistrationService::EmailExistsError
          end
        end

        context 'unknown' do
          let!(:error) { '{"Error":"Unknown","ErrorDescription":"Incorrect MiddleName: A","Params":null}' }

          it do
            expect { subject.register! }.to raise_error W1::RegistrationService::UnknownError
          end
        end
      end
    end
  end
end
