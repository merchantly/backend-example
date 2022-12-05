require 'rails_helper'

RSpec.describe I18n::Backend::Vendor, type: :model do
  subject { described_class.new(vendor) }

  let!(:vendor) { create :vendor }

  let(:locale) { :ru }
  let(:key) { 'entities' }

  it do
    expect(subject.translate(locale, key)).to be_a Hash
  end

  it 'deep key' do
    vendor.translations.create! locale: locale, key: 'order.some', value: 'some'
    expect(subject.translate(locale, 'order.submit')).to be_a String
    expect(subject.translate(locale, 'order.some')).to eq 'some'
  end
end
