require 'rails_helper'

# при смене валюты запускается воркер для обновления валюты в товарах
RSpec.describe VendorTitleTemplates, type: :model do
  let(:vendor) { create :vendor }

  it { expect(vendor.meta_title_templates).to be_nil }

  context do
    let(:content) { 'test' }

    specify do
      vendor.meta_title_templates_ru_vendors = content
      expect(vendor.meta_title_templates_ru_vendors).to eq content
      vendor.save!
      vendor.reload
      expect(vendor.meta_title_templates_ru_vendors).to eq content
      expect(vendor.meta_title_templates_ru).to be_present
    end
  end
end
