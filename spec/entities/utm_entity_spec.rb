require 'rails_helper'

RSpec.describe UtmEntity do
  subject { described_class.build attrs }

  let(:utm_source) { generate :utm }

  context 'symbols' do
    let(:attrs) { { utm_source: utm_source, abc: 123 } }

    it { expect(subject.utm_source).to eq utm_source }
  end

  context 'string' do
    let(:attrs) { { 'utm_source' => utm_source, 'abc' => 123 } }

    it { expect(subject.utm_source).to eq utm_source }
  end
end
