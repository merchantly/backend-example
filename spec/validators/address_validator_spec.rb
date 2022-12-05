require 'rails_helper'

module Test
  AddressValidatable = Struct.new(:address) do
    include ActiveModel::Validations

    validates :address, address: true
  end
end

RSpec.describe AddressValidator do
  include CurrentVendor

  subject { Test::AddressValidatable.new value }

  let!(:vendor) { create :vendor }

  before do
    set_current_vendor vendor
  end

  after do
    set_current_vendor nil
  end

  context 'is valid' do
    describe do
      let(:value) { 'Улица д. 44/28 квартира 349' }

      it { expect(subject.valid?).to eq true }
    end

    describe do
      let(:value) { 'ул. Тестовый адрес, 12/25 кв.9-87' }

      it { expect(subject.valid?).to eq true }
    end

    describe do
      let(:value) { 'Фёдорова Абрамова 8-10444' }

      it { expect(subject.valid?).to eq true }
    end
  end
end
