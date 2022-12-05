require 'rails_helper'

RSpec.describe OrderPaymentYandexKassa, type: :model do
  subject { order.order_payment }

  let!(:order) { create :order, :payment_yandex_kassa }

  it { expect(subject).to be_persisted }
  it { expect(subject).to be_a described_class }
end
