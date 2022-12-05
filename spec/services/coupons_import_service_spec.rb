require 'rails_helper'

describe CouponsImportService do
  subject { described_class.new(vendor) }

  let(:vendor) { create :vendor }
  # Такой купон есть в файле
  let(:coupon) { create :coupon_single, vendor: vendor, code: 'addfd', discount: 12 }
  let(:file) { fixture_file_upload('import/csv_file.csv', 'text/csv') }

  describe '#perform' do
    context 'regular' do
      it 'does not raise error' do
        expect do
          subject.perform(file: file, skip_headers: true)
        end.not_to raise_error
      end
    end

    context 'Попытка импортировать уже существующий купон вызывает ошибку' do
      before { coupon }

      it 'raises error' do
        expect do
          subject.perform(file: file, skip_headers: true)
        end.to raise_error(BaseImportService::ImportError)
      end
    end

    context 'without skip_headers' do
      it 'raises error' do
        expect do
          subject.perform(file: file, skip_headers: false)
        end.to raise_error(BaseImportService::ImportError)
      end
    end
  end
end
