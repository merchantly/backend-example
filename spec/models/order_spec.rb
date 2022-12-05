require 'rails_helper'

RSpec.describe Order, type: :model, sidekiq: :inline do
  let_it_be(:vendor) { create :vendor }
  let_it_be(:order) { create :order, :items, vendor: vendor }

  subject { order }

  it 'Попытка создать заказ без доставки и оплаты не должа заканчиваться не ожиданным исклчением' do
    expect { create :order, delivery_type: nil, payment_type: nil }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context 'У клиента устанавливается дата последнего заказа' do
    let_it_be(:client) { create :client, vendor: vendor }

    # orders_count, last_order_id
    it { expect(client.orders_count).to eq 0 }
    it { expect(client.last_order_id).to be_nil }

    context do
      let!(:order) { create :order, client: client }

      before do
        client.reload
      end

      it { expect(order.client).to eq client }
      it { expect(client.orders_count).to eq 1 }
      it { expect(client.last_order_id).to eq order.id }
    end
  end

  context do
    let_it_be(:order_condition) { create :order_condition, vendor: vendor, action: 'notification', event: 'on_create', after_time_minutes: 1 }

    it do
      expect(subject.description).to be_a String
    end

    it do
      expect_any_instance_of(OrderCondition).not_to receive(:do_action!)
      expect(OrderConditionDelayWorker).to receive(:perform_in)
      subject.on_created
    end
  end

  context do
    let_it_be(:order_condition) { create :order_condition, vendor: vendor, action: 'notification', event: 'on_create', after_time_minutes: nil }

    it do
      expect(OrderConditionDelayWorker).not_to receive(:perform_in)
      subject.on_created
    end
  end

  context do
    let_it_be(:order_condition) { create :order_condition, vendor: vendor, action: 'change_state', event: 'on_create', to_order_workflow_state_id: vendor.workflow_states.last.id, after_time_minutes: 1 }

    it do
      subject.on_created
      subject.reload
      expect(subject.workflow_state_id).to eq order_condition.to_order_workflow_state_id
    end
  end

  context 'уведомляет online-кассу' do
    subject { create :order, :items, payment_type: payment_type, vendor: vendor }

    let(:payment_type) do
      create :vendor_payment,
             title: 'starrys',
             vendor: vendor,
             online_kassa_client_id: 123,
             online_kassa_password: 123,
             online_kassa_provider: :starrys,
             online_kassa_cert: 'cert',
             online_kassa_key: 'key'
    end

    it 'ККТ' do
      expect_any_instance_of(Starrys::Requestor).to receive(:perform)
      subject.order_payment.pay!
      expect(subject.reload.online_kassa_notified_at).to be_present
    end
  end
end
