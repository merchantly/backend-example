require 'rails_helper'

RSpec.describe YMLCatalog::Import do
  subject { described_class.new(vendor: vendor, body: File.read(file)) }

  let(:file) { fixture_file_upload('yandex/import.xml', 'text/xml') }
  let!(:vendor) { create :vendor }

  it 'YMLCatalog::Import perform return 100' do
    expect(subject.perform).to eq 100
  end
end
