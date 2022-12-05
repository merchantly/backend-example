require 'rails_helper'

RSpec.describe Vendor, type: :model do
  context 'не регистрирует вендора с уже существующим доменом' do
    let(:subdomain) { 'somedomain' }

    before do
      create :vendor, subdomain: subdomain
    end

    it do
      expect { create :vendor, subdomain: subdomain }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'Создание' do
    let(:vendor) { create :vendor }

    it 'Фабрика' do
      expect(vendor).to be_valid
    end
  end

  describe 'Обновление индексов' do
    let(:vendor)        { create :vendor, :currency_eur }
    let(:new_currency)  { Money::Currency.find_by_iso_numeric(643) }

    it 'Планирование работы индексирования при обновлении валюты, успешно' do
      expect(VendorReindexWorker).to receive(:perform_async).with vendor.id
      vendor.update currency_iso_code: new_currency.iso_code
    end
  end

  context 'Регистрация зарезервированного домена, неудачно' do
    let(:subdomain) { 'admin' }

    it do
      expect(Settings.ignored_subdomains.include?(subdomain)).to be
      expect { create :vendor, subdomain: subdomain }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'contacts validation' do
    let!(:vendor) { create :vendor }

    context 'valid contacts' do
      let(:contacts) { "+7 999 999 99 99\n+70000000000\ntest@test.com\nг. Оренбург" }

      before { vendor.update! contacts: contacts }

      it 'must save contacts' do
        expect(vendor.contacts).to eq contacts
        expect(vendor.contacts_array).to eq ['+7 999 999 99 99', '+70000000000', 'test@test.com', 'г. Оренбург']
        expect(Phoner::Phone.valid?(vendor.contacts_array[0])).to eq true
        expect(Phoner::Phone.valid?(vendor.contacts_array[1])).to eq true
        expect(ValidateEmail.valid?(vendor.contacts_array[2])).to eq true
        expect(Phoner::Phone.valid?(vendor.contacts_array[3])).to eq false
        expect(ValidateEmail.valid?(vendor.contacts_array[3])).to eq false
      end
    end
  end
end
