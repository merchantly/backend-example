require 'rails_helper'

describe MoyskladImporting::PropertiesUpdater do
  subject { described_class.new universe: moysklad_universe }

  let(:vendor)            { create :vendor }
  let(:synced_at)         { Time.zone.now }
  let(:vendor_logger)     { MoyskladImporting::VendorLogger.new vendor: vendor, synced_at: synced_at }
  let(:moysklad_universe) { MoyskladImporting::Universe.new vendor: vendor, synced_at: synced_at, vendor_logger: vendor_logger }

  before do
    vendor.update moysklad_login: 'login', moysklad_password: 'password'
  end

  describe 'создаем новые свойства' do
    let(:resource)  { [attribute_metadata] }
    let(:property) { vendor.properties.last }

    context 'текстовое свойство' do
      let(:attribute_metadata) do
        double(
          type: 'string',
          required: false,
          name: 'name',
          position: 0,
          description: 'desc',
          id: 'id',
          dump: 'some',
          externalcode: 'somecode'
        )
      end

      before do
        expect(subject).to receive(:resource).at_least(:once).and_return resource
        subject.perform!
      end

      it 'creates property' do
        expect(vendor.properties).to have(1).items
        expect(property.ms_uuid).to eq attribute_metadata.id
      end
    end

    context 'справочник' do
      let(:attribute_metadata) do
        double(
          type: 'customentity',
          customEntityMeta: double(id: dictionary.ms_uuid),
          required: true,
          name: 'name',
          position: 0,
          description: 'desc',
          id: 'id',
          dump: '<xml />',
          externalcode: 'somecode'
        )
      end
      let(:dictionary) { create :dictionary, vendor: vendor }

      before do
        expect(subject).to receive(:resource).at_least(:once).and_return resource
        subject.perform!
      end

      it 'creates property' do
        expect(property.ms_uuid).to eq attribute_metadata.id
        expect(vendor.properties).to have(1).items
      end

      context 'архивируем созданное свойство' do
        before do
          mu = MoyskladImporting::Universe.new vendor: vendor, synced_at: synced_at + 1.day, vendor_logger: vendor_logger
          updater = described_class.new universe: mu
          expect(updater).to receive(:resource).at_least(:once).and_return []
          updater.perform!
        end

        it 'кладем в архив если список свойств от сервера пуст' do
          expect(vendor.properties).to have(1).items
          expect(vendor.properties.alive).to be_empty
          expect(vendor.properties.archive).to have(1).items
        end

        context 'и обратно восстанавливаем' do
          before do
            mu = MoyskladImporting::Universe.new vendor: vendor, synced_at: synced_at + 1.day, vendor_logger: vendor_logger
            updater = described_class.new universe: mu
            expect(updater).to receive(:resource).at_least(:once).and_return resource
            updater.perform!
          end

          it do
            expect(vendor.properties).to have(1).items
            expect(vendor.properties.archive).to be_empty
            expect(vendor.properties.alive).to have(1).items
          end
        end
      end
    end
  end
end
