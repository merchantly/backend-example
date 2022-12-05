require 'rails_helper'

describe Export::TorgMail::Yml do
  subject { described_class.new(vendor) }

  let(:vendor) { create :vendor, :with_products }

  it do
    expect(subject.generate).to be_a Nokogiri::XML::Builder
  end
end
