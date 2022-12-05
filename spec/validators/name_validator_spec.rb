require 'rails_helper'

module Test
  NameValidatable = Struct.new(:name) do
    include ActiveModel::Validations

    validates :name, name: true
  end
end

RSpec.describe NameValidator do
  include CurrentVendor

  subject { Test::NameValidatable.new value }

  let!(:vendor) { create :vendor }

  before do
    set_current_vendor vendor
  end

  after do
    set_current_vendor nil
  end

  context 'is valid' do
    let(:value) { 'test name' }

    it do
      expect(subject.valid?).to eq true
    end
  end

  context 'is valid with ё' do
    let(:value) { 'Артём' }

    it do
      expect(subject.valid?).to eq true
    end
  end

  context 'is invalid' do
    let(:value) { 'test $ name' }

    it do
      expect(subject.valid?).to eq false
    end
  end
end
