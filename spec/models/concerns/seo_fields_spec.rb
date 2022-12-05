require 'rails_helper'

RSpec.describe SeoFields, type: :model do
  let!(:required_methods) { %i[default_path h1 meta_title meta_description meta_keywords] }
  let(:vendor) { create :vendor }
  let(:product) { create :product }
  let(:category) { create :category }
  let(:dictionary) { create :dictionary }
  let(:dictionary_entity) { create :dictionary_entity }
  let(:lookbook) { create :lookbook }
  let(:content_page) { create :content_page }

  describe 'included in' do
    shared_examples 'seo_ready' do
      describe do
        it 'and responds to required methods' do
          expect(required_methods.all? { |x| subject.respond_to? x }).to eq true
        end
      end
    end

    describe 'vendor' do
      subject { vendor }

      it_behaves_like 'seo_ready'
    end

    describe 'product' do
      subject { product }

      it_behaves_like 'seo_ready'
    end

    describe 'category' do
      subject { category }

      it_behaves_like 'seo_ready'
    end

    describe 'dictionary' do
      subject { dictionary }

      it_behaves_like 'seo_ready'
    end

    describe 'dictionary_entity' do
      subject { dictionary_entity }

      it_behaves_like 'seo_ready'
    end

    describe 'lookbook' do
      subject { lookbook }

      it_behaves_like 'seo_ready'
    end

    describe 'content_page' do
      subject { content_page }

      it_behaves_like 'seo_ready'
    end
  end
end
