require 'rails_helper'

describe OrderCommands do
  let!(:order) { create :order, :items, :payment_w1 }

  it do
    expect(order.commands).to be_a OrderCommands::Handler
  end
end
