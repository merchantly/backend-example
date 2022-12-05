require 'rails_helper'

describe BaseImportService do
  subject { described_class }

  let(:xls_file) { fixture_file_upload('import/xls_file.xls', 'application/vnd.ms-excel') }
  let(:xlsx_file) { fixture_file_upload('import/xlsx_file.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') }
  let(:csv_file) { fixture_file_upload('import/csv_file.csv', 'text/csv') }

  describe '#read' do
    context 'csv' do
      it 'returns Roo::CSV' do
        file = subject.read(csv_file)
        expect(file).to be_a(Enumerator)
      end
    end

    context 'xls' do
      it 'returns Roo::Excel' do
        file = subject.read(xls_file)
        expect(file).to be_a(Enumerator)
      end
    end

    context 'xlsx' do
      it 'returns Roo::Excelx' do
        file = subject.read(xlsx_file)
        expect(file).to be_a(Enumerator)
      end
    end
  end
end
