require 'rails_helper'

describe ProductBuilder do
  let!(:vendor)   { create :vendor, sellable_infinity: true }

  describe 'новый product' do
    subject { described_class.new(vendor: vendor, product: nil, params: params).build }

    let!(:params) { ActiveSupport::HashWithIndifferentAccess.new title: 'title', price: 123, is_manual_published: true }

    it { expect(subject).to be_a Product }
    it { expect(subject).to be_valid }

    it { expect(subject.has_ordering_goods).to be_truthy }
    it { expect(subject.is_ordering).to be_truthy }

    context do
      before do
        subject.save!
      end

      it { expect(subject).to be_persisted }
      it { expect(subject.has_ordering_goods).to be_truthy }
      it { expect(subject.is_ordering).to be_truthy }
    end
  end

  describe 'новый товар с text block' do
    subject { described_class.new(vendor: vendor, product: nil, params: params).build }

    let(:params) do
      ActiveSupport::HashWithIndifferentAccess.new(
        'is_manual_published' => '1',
        'is_new' => '0',
        # "image_ids"=>["38595", "38594", ""],
        'title' => 'were',
        'price' => '1232',
        'sale_price' => '',
        'is_sale' => '0',
        # "category_ids"=>["4177", "4178"],
        'description' => '',
        'article' => '1232',
        'quantity' => '',
        # "custom_attributes"=>{"2807"=>{"dictionary_entity_id"=>"12970"}},
        'text_blocks_attributes' => { '1449121751181' => { 'title' => 'werqwr',
                                                           'content' => '<p>qwerwe</p>',
                                                           '_destroy' => 'false',
                                                           'vendor_id' => vendor.id } },
        'video_url' => '',
        'slug_attributes' => { 'id' => '', 'path' => '' },
        'h1' => '',
        'meta_title' => '',
        'meta_description' => '',
        'meta_keywords' => '',
        'show_similar_products' => 'auto',
        'similar_products' => ['']
      )
    end

    before do
      subject.save!
    end

    it { expect(subject).to be_persisted }
    it { expect(subject.has_ordering_goods).to be_truthy }
    it { expect(subject.is_ordering).to be_truthy }
  end

  describe 'существующий product' do
    subject { described_class.new(vendor: vendor, product: product, params: params).build }

    let!(:params)   { ActiveSupport::HashWithIndifferentAccess.new title: 'title' }
    let!(:product)  { create :product, vendor: vendor }

    it do
      expect(subject).to be_a Product
      expect(subject).to be_persisted
      expect(subject).to be_valid
    end

    context 'category_ids' do
      let!(:category1) { create :category }
      let!(:category2) { create :category }
      let(:params) { { 'category_ids' => [category1.id.to_s, category2.id.to_s, '', nil, category1.id.to_s, category2.id] } }

      it 'категории осотритованы, убрано линее и привратились в цифры' do
        expect(subject.category_ids).to eq [category1.id, category2.id]
      end
    end

    context 'image_ids' do
      let(:params) { { 'image_ids' => ['1', '2', '', nil, '1', 2] } }

      it 'убрано линее и привратились в цифры' do
        expect(subject.image_ids).to eq [1, 2, 1, 2]
      end
    end

    context 'custom_attributes' do
      context 'новый dictionary entity' do
        let!(:property) { create :property_dictionary, vendor: vendor }
        let(:title) { 'adsadassadasd' }
        let!(:params) do
          {
            'custom_attributes' => {
              property.id => {
                dictionary_entity_id: ProductBuilder::NEW_ID, dictionary_entity_title: title
              }
            }
          }
        end

        let!(:custom_attribute) { subject.custom_attributes.first }

        it 'контролька' do
          expect(property.dictionary.entities).to be_empty
        end

        it do
          subject.save!
          expect(subject.custom_attributes).to have(1).items
          expect(custom_attribute).to be_a AttributeDictionary
          expect(custom_attribute.readable_value).to eq title
          expect(property.dictionary.reload.entities).to have(1).items
          expect(custom_attribute.property).to eq property
        end
      end

      describe '#build_custom_attributes' do
        let!(:property) { create :property_string, vendor: vendor }
        let!(:value)    { 'some value' }
        let!(:params) { { 'custom_attributes' => { property.id => { 'value' => value } } } }

        let!(:custom_attribute) { subject.custom_attributes.first }

        it do
          expect(subject.custom_attributes).to have(1).items
          expect(custom_attribute).to be_a Attribute
          expect(custom_attribute.value).to eq value
          expect(custom_attribute.property).to eq property
        end

        context 'reset' do
          let!(:params) { { 'custom_attributes' => {} } }

          it 'must reset attributes' do
            expect(subject.custom_attributes).to have(0).items
          end
        end

        context 'reset' do
          let!(:params) { { 'custom_attributes' => [''] } }

          it 'must reset attributes' do
            expect(subject.custom_attributes).to have(0).items
          end
        end
      end

      context 'reset' do
        let!(:params) { { 'custom_attributes' => {} } }

        it 'must reset attributes' do
          expect(subject.custom_attributes).to have(0).items
        end
      end
    end
  end
end
