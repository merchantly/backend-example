require 'rails_helper'

RSpec.describe Slug, type: :model do
  subject { build :slug_resource, path: path, vendor: vendor }

  let!(:vendor) { create :vendor }

  context 'правильный путь' do
    let(:path) { '/asdsa' }

    it { expect(subject).to be_valid }
  end

  context 'слеш в конце убирается' do
    let(:path) { '/asdsa/' }

    before do
      subject.valid?
    end

    it { expect(subject.path).to eq '/asdsa' }
  end

  context 'точки запрещены' do
    let(:path) { '/asd.asd' }

    it { expect(subject).to be_invalid }
  end

  context 'без слеша в начале принимается и добавляет автоматичски слеш' do
    let(:path) { 'asdsa' }

    it { expect(subject).to be_valid }
    it { subject.valid?; expect(subject.path).to eq "/#{path}" }
  end

  context 'с пробелами не принимаем' do
    let(:path) { '/asdsa adas' }

    it { expect(subject).not_to be_valid }
  end

  describe 'при добавление slug-а history_path меняется' do
    let(:path) { '/abc' }
    let!(:history_path) { create :history_path, vendor: vendor, path: path }

    before do
      create :slug_resource, path: path, vendor: vendor
    end

    it do
      expect(history_path.reload.state).to eq 'slugged'
    end
  end
end
