require 'rails_helper'

describe PickupPointsImportService do
  subject { described_class.new(delivery) }

  let(:delivery) { create :vendor_delivery }
  let(:file) { fixture_file_upload('import/pickup_points.csv', 'text/csv') }

  describe '#perform' do
    context 'regular' do
      it 'does not raise error' do
        expect do
          subject.perform(file: file, skip_headers: true)
        end.not_to raise_error
      end
    end

    # context 'Попытка импортировать уже существующий pickup_point НЕ вызывает ошибку' do
    # before { coupon }
    # it 'raises error' do
    # expect do
    # subject.perform(file: file, skip_headers: true)
    # end.to raise_error(BaseImportService::ImportError)
    # end
    # end
  end
end
