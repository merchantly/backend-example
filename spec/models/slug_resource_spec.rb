require 'rails_helper'

RSpec.describe SlugResource, type: :model do
  let!(:product) { create :product }
  let(:path) { '/some' }

  it do
    HistoryPath.delete_all
    create :slug_resource, path: path, resource: product
    hp = HistoryPath.last
    expect(hp).to be_present
    expect(hp.path).to eq path
    expect(hp.resource).to eq product
  end

  context do
    subject { create :slug_resource, resource: resource }

    let(:resource) { create :product }

    it do
      expect(subject).to be_persisted
    end
  end
end
