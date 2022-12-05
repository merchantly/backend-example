require 'rails_helper'

describe VendorRobotsEditor do
  context do
    let!(:vendor) { create :vendor }

    it do
      expect(vendor.robots).to match(/Host: #{vendor.public_url}/)
      expect(vendor.robots).to match(/Sitemap: #{vendor.sitemap_url}/)
      expect(vendor.robots).to match(/Disallow: \/orders/)
      expect(vendor.robots).to match(/Disallow: \/cart/)
    end
  end

  context do
    subject { described_class.new(vendor: vendor) }

    describe '#set_defaults' do
      context 'empty robots' do
        let(:vendor) { create :vendor, robots: '' }
        before { subject.set_defaults }
        it do
          expect(vendor.robots).to match(/Host: #{vendor.public_url}/)
          expect(vendor.robots).to match(/Sitemap: #{vendor.sitemap_url}/)
          expect(vendor.robots).to match(/Disallow: \/orders/)
          expect(vendor.robots).to match(/Disallow: \/cart/)
        end
      end

      context 'host and sitemap present' do
        let(:vendor) { create :vendor, domain: 'asdf.ru', robots: 'abracadabra' }
        before { subject.set_defaults }
        it do
          expect(vendor.robots).to match(/Host: http:\/\/asdf\.ru/)
          expect(vendor.robots).to match(/Sitemap: http:\/\/asdf\.ru\/sitemap\.xml.gz/)
        end
      end
    end

    describe '#reset' do
      let(:vendor) { create :vendor, domain: 'asdf.ru', robots: 'abracadabra' }
      before { subject.reset }
      it do
        expect(vendor.robots).to match(/Host: #{vendor.public_url}/)
        expect(vendor.robots).to match(/Sitemap: #{vendor.sitemap_url}/)
        expect(vendor.robots).to match(/Disallow: \/orders/)
        expect(vendor.robots).to match(/Disallow: \/cart/)
      end
    end

    describe '#update_host' do
      let(:vendor) { create :vendor, domain: 'asdf.ru', robots: 'Host: adsf.ru' }
      before { subject.update_host }
      it { expect(vendor.robots).to match(/Host: #{vendor.public_url}/) }
    end
  end
end
