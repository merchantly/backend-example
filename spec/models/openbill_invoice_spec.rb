require 'rails_helper'

RSpec.describe OpenbillInvoice, type: :model do
  subject { create :openbill_invoice }

  let(:summa) { 123 }

  it 'должен автогенерироваться phone_confirmation для телефона' do
    subject.amount = summa
    expect(subject.amount).to eq summa.to_money(:rub)
  end
end
