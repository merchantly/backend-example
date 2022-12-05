require 'rails_helper'

RSpec.describe HistoryPath, type: :model do
  subject { create :history_path, path: path }

  let(:path) { '/some' }

  it do
    expect(subject).to be_persisted
    expect(subject.content_type).to eq 'text/html'
  end

  context 'jpeg' do
    let(:path) { '/some.JPG' }

    it do
      expect(subject).to be_persisted
      expect(subject.content_type).to eq 'image/jpeg'
    end
  end
end
