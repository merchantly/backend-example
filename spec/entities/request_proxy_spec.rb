require 'rails_helper'

RSpec.describe RequestProxy, type: :request do
  subject { described_class.new req }

  let(:env)          { { 'HTTP_HOST' => host } }
  # ActionDispatch::Request
  let(:req)          { ActionDispatch::TestRequest.new env }
  let(:domain_zones) { ['kiiiosk.com.ua', 'kiiiosk.store'] }

  before do
    allow(Settings).to receive(:domain_zones).and_return domain_zones
  end

  # Это такой способ очищать после себя глобальный tld_length,
  # который может оказаться равен 2 после этого теста и тогда, например:
  # spec/controllers/system/operators_controller_spec.rb не будет проходить
  # after do
  # request.tld_length = 1
  # end

  context 'чужой домен' do
    let(:host) { 'app.3001.vkontraste.ru' }

    it do
      expect(subject).not_to be_domain_zone
      expect(subject).not_to be_app
    end
  end

  context 'свой домен' do
    let(:host)         { 'kiiiosk.store' }

    it do
      expect(subject).to be_domain_zone
      expect(subject).to be_app
      expect(subject.tld_length).to eq 1
    end
  end

  context 'свой домен' do
    let(:host)         { 'kiiiosk.com.ua' }

    it do
      expect(subject).to be_domain_zone
      expect(subject).to be_app
      expect(subject.tld_length).to eq 2
    end
  end
end
