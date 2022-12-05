require 'rails_helper'

RSpec.describe VendorTranslations, type: :model do
  subject { vendor.translate locale, key, fallback: nil }

  let!(:vendor) { create :vendor }

  let(:locale) { 'ru' }
  let(:key) { 'entities' }

  it do
    expect(subject).to be_a Hash
  end
end
