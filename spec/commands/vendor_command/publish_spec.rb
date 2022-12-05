require 'rails_helper'

describe VendorCommand::Publish do
  subject { described_class.new(vendor: vendor) }

  let(:tariff) { create :tariff }

  describe '#call' do
    context 'working_to present' do
      let(:vendor) do
        create :vendor, is_published: false, paid_to: Date.current - 2.weeks, working_to: working_to, tariff: tariff
      end
      let(:working_to) { Date.current + 1.week }

      it do
        subject.call
        expect(vendor.is_published).to be_truthy
      end
    end

    context 'working_to not present' do
      let(:vendor) do
        create :vendor, is_published: false, paid_to: nil, working_to: nil, tariff: tariff
      end

      it do
        expect { subject.call }.to raise_error described_class::NotPaidError
        expect(vendor.is_published).to be_falsey
      end
    end

    context 'не работаем' do
      let(:vendor) do
        create :vendor, is_published: false, paid_to: Date.current - 2.weeks, working_to: working_to, tariff: tariff
      end
      let(:working_to) { Date.current - 1.day }

      it do
        expect { subject.call }.to raise_error described_class::NotPaidError
        expect(vendor.is_published).to be_falsey
      end
    end
  end
end
