require 'rails_helper'

describe ProductsSpreadsheet do
  subject { described_class.new vendor, vendor.products.active }

  let(:vendor) { create :vendor, :with_products }
  let!(:product) { create :product, vendor: vendor, category: nil }

  it do
    expect { subject.to_csv }.not_to raise_error
  end
end
