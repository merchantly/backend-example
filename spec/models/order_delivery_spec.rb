require 'rails_helper'

RSpec.describe OrderDelivery, type: :model do
  include CurrentVendor
  subject { order.order_delivery }

  let!(:vendor) { create :vendor }
  let(:order) { create :order, :delivery_cse, vendor: vendor }

  before do
    set_current_vendor vendor
  end

  it { expect(subject).to be_persisted }

  describe 'states' do
    shared_examples 'cancelable' do
      describe 'canceled' do
        before { subject.cancel! }

        it 'is canceled' do
          expect(subject.state).to eq OrderDelivery::STATE_CANCELED
          expect(subject.order.admin_comments.auto.first.body).to eq I18n.t("order_delivery_states_comments.#{OrderDelivery::STATE_CANCELED}")
        end
      end
    end

    shared_examples 'uncancelable' do
      describe 'canceled' do
        it 'raises error' do
          expect do
            subject.cancel!
          end.to raise_error Workflow::NoTransitionAllowed
        end
      end
    end

    shared_examples 'donable' do
      describe 'done' do
        before { subject.done! }

        it 'is done' do
          expect(subject.state).to eq OrderDelivery::STATE_DONE
          expect(subject.order.admin_comments.auto.first.body).to eq I18n.t("order_delivery_states_comments.#{OrderDelivery::STATE_DONE}")
        end
      end
    end

    shared_examples 'undonable' do
      describe 'done' do
        it 'raises error' do
          expect do
            subject.done!
          end.to raise_error Workflow::NoTransitionAllowed
        end
      end
    end

    shared_examples 'deliverable' do
      describe 'delivery' do
        before { subject.delivery! }

        it 'is delivery' do
          expect(subject.state).to eq OrderDelivery::STATE_DELIVERY
          expect(subject.order.admin_comments.auto.first.body).to eq I18n.t("order_delivery_states_comments.#{OrderDelivery::STATE_DELIVERY}")
        end
      end
    end

    describe 'not_needed' do
      before { subject.not_needed! }

      it_behaves_like 'cancelable'
      it_behaves_like 'donable'
      it { expect(subject.state).to eq OrderDelivery::STATE_NOT_NEEDED }

      context 'transitions to delivery' do
        before { subject.delivery! }

        it 'does not change state' do
          expect(subject.state).to eq OrderDelivery::STATE_NOT_NEEDED
        end
      end
    end

    describe 'new' do
      it_behaves_like 'deliverable'
      it_behaves_like 'cancelable'
      it_behaves_like 'donable'
      it { expect(subject.state).to eq OrderDelivery::STATE_NEW }

      context 'payment received' do
        context 'доставка при удачной оплате' do
          before do
            vendor.order_conditions.create! vendor_payment: subject.order.payment_type, action: 'delivery', event: 'on_pay_success'
          end

          it 'changes state to delivery' do
            subject.order.order_payment.pay!
            expect(subject.reload.state).to eq OrderDelivery::STATE_DELIVERY
          end
        end

        context 'deliver_on_payment = false' do
          it 'доставка при не удачной оплате' do
            subject.order.order_payment.pay!
            expect(subject.reload.state).to eq OrderDelivery::STATE_NEW
          end
        end
      end
    end

    describe 'delivery' do
      before { subject.delivery! }

      it_behaves_like 'deliverable'
      it_behaves_like 'cancelable'
      it_behaves_like 'donable'
      it { expect(subject.state).to eq OrderDelivery::STATE_DELIVERY }

      context 'external_id update' do
        it 'does not change state' do
          subject.update external_id: '321'
          expect(subject.reload.state).to eq OrderDelivery::STATE_DELIVERY
        end
      end
    end

    describe 'done' do
      before { subject.done! }

      it_behaves_like 'uncancelable'
      it { expect(subject.state).to eq OrderDelivery::STATE_DONE }
    end

    describe 'canceled' do
      before { subject.cancel! }

      it_behaves_like 'undonable'
      it { expect(subject.state).to eq OrderDelivery::STATE_CANCELED }
    end
  end

  describe 'pickup delivery expiration' do
    it { expect(subject.expires_at).to eq nil }

    context 'OrderDeliveryPickup' do
      let(:order) { create :order, :delivery_pickup, vendor: vendor }

      it { expect(subject.expires_at).to be_present }
    end
  end
end
