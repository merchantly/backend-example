require 'rails_helper'

RSpec.describe Operator, type: :model do
  context do
    let(:phone) { generate :phone }

    it 'должен автогенерироваться phone_confirmation для телефона' do
      operator = build :operator, phone: phone
      operator.save!

      expect(operator.phone_confirmations.where(phone: phone)).to be_exists
    end
  end
end
