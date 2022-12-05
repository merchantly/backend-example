require 'rails_helper'

describe CustomOrderMailer do
  subject { described_class.send_client_mail method, order.id }

  let(:order) { create :order }
  let(:client_to) { "#{order.name} <#{order.email}>" }

  describe '#payment_link' do
    let(:method) { :payment_link }

    it 'имеет номер заказа' do
      expect(subject).to have_body_text order.public_id
    end

    it 'имеет ссылку на оплату' do
      expect(subject).to have_body_text order.payment_url
    end

    it { expect(subject).to deliver_to client_to }
  end

  describe '#paid' do
    let(:method) { :paid }

    it 'имеет номер заказа' do
      expect(subject).to have_body_text order.public_id
    end

    it 'имеет ссылку на оплату' do
      expect(subject).to have_body_text order.client_order_url
    end

    it { expect(subject).to deliver_to client_to }
  end

  describe '#new_order' do
    let(:method) { :new_order }

    it 'имеет номер заказа' do
      expect(subject).to have_body_text order.public_id
    end

    it { expect(subject).to deliver_to client_to }
  end

  describe '#workflow_changed' do
    let(:method) { :workflow_changed }

    it 'имеет номер заказа' do
      expect(subject).to have_body_text order.public_id
    end

    it { expect(subject).to deliver_to client_to }
  end
end
