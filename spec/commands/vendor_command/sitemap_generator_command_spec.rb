require 'rails_helper'

describe VendorCommand::SitemapGeneratorCommand, :vcr do
  subject { described_class.new(vendor) }

  before :all do
    Vendor.destroy_all
  end

  let!(:vendor) { create :vendor } # Важно именно 1, он сохранен в vcr
  let!(:blog_post) { create :blog_post, vendor: vendor }
  let!(:category) { create :category, vendor: vendor }
  let!(:product) { create :product, vendor: vendor, category: category }
  let!(:lookbook) { create :lookbook, vendor: vendor }
  let!(:content_page) { create :content_page, vendor: vendor }

  before do
    allow(vendor).to receive(:id).and_return 1
  end

  it do
    expect(subject.call).to eq 5
  end
end
