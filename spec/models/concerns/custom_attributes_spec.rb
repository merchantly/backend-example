require 'rails_helper'

RSpec.describe CustomAttributes, type: :model do
  let_it_be(:vendor)   { create :vendor }
  let_it_be(:property) { create :property_string, vendor: vendor }
  let_it_be(:product)  { create :product, vendor: vendor }

  let_it_be(:value)    { SecureRandom.hex }

  let_it_be(:attr_method) { property.attr_method }

  subject { product }

  shared_examples 'fine' do
    it do
      expect(subject.send(attr_method)).to eq value
    end

    it do
      expect(subject.custom_attributes).to have(1).item
    end

    it do
      expect(subject.custom_attributes.first.property).to eq property
    end

    it do
      expect(subject.custom_attributes.first.value).to eq value
    end
  end

  describe 'assign_attributes' do
    before do
      subject.assign_attributes attr_method => value
    end

    it_behaves_like 'fine'
  end

  describe '#attr_?' do
    before do
      subject.send "#{attr_method}=", value
    end

    it_behaves_like 'fine'

    context 'сохраняем, восстанавливаем' do
      before do
        product.save
        product.reload
      end

      it_behaves_like 'fine'
    end

    describe 'clear_undefined_custom_attributes' do
      it_behaves_like 'fine'

      context 'не определенный параметр' do
        before do
          subject.data[:invalid_key] = 123
        end

        it { expect(subject.data.keys).to have(2).items }

        it_behaves_like 'fine'

        context 'удаляем' do
          before do
            subject.clear_undefined_custom_attributes
          end

          it { expect(subject.data.keys).to have(1).items }
          it { expect(subject.data_changed?).to be true }

          it_behaves_like 'fine'
        end
      end
    end
  end

  describe 'bad attributes' do
    let(:product) { create :product, vendor: vendor, data: { property.id => '123', 'asdf' => '321' } }

    it do
      expect(product.custom_attributes.count).to eq 1
      expect(product.custom_attributes.first.value).to eq '123'
    end
  end

  describe '#set_attribute_by_key' do
    let(:product) { create :product, vendor: vendor }
    let(:key) { 'brand' }
    let(:value) { 'Sony' }

    it 'контролька' do
      expect(product.custom_attributes).to be_empty
    end

    context do
      before do
        product.set_attribute_by_key key, value
        product.save!
      end

      it { expect(product.reload.data).to have(1).items }
      it { expect(product.reload.custom_attributes).to have(1).items }

      it 'brand это dictionary, значит возаращается ID, а не значение' do
        expect(product.reload.custom_attributes.first.value).not_to eq value
      end

      it { expect(product.reload.custom_attributes.first.property.type).to eq PropertyDictionary.name }
    end
  end

  describe '#set_attribute' do
    let(:product) { create :product, vendor: vendor }

    it { expect(product.custom_attributes).to be_empty }

    context do
      let(:attribute) { property.build_attribute_by_value 'test' }

      before { product.set_attribute attribute }

      it { expect(product.custom_attributes).to have(1).items }
    end
  end
end
