require 'rails_helper'

RSpec.describe ShortLink, type: :model do
  subject do
    described_class.generate url
  end

  let(:url) { 'http://ya.ru/' }

  context do
    it 'создается с первого раза нормально' do
      expect(subject).to be_a(String)
      expect(described_class.find_by(url: url)).to be_persisted
    end

    it 'повторно отдает тот-же slug' do
      short_link1 = described_class.generate url
      short_link2 = described_class.generate url

      expect(short_link1).to eq short_link2
    end
  end

  context 'когда случайно сгенерировался тот-же slug' do
    before do
      expect(described_class).to receive(:generate_unique_key).twice.and_return 'test'
    end

    it 'повторно отдает тот-же slug' do
      short_link1 = described_class.generate url
      short_link2 = described_class.generate url

      expect(described_class.count).to eq 1
      expect(short_link1).to eq short_link2
    end
  end
end
