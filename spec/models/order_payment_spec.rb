require 'rails_helper'

RSpec.describe OrderPayment, type: :model do
  include CurrentVendor

  subject { order.order_payment }

  let!(:vendor) { create :vendor }
  let(:order)   { create :order, :payment_w1, vendor: vendor }

  before do
    set_current_vendor vendor
  end

  it { expect(subject).to be_persisted }

  describe 'states' do
    shared_examples 'failable' do
      describe 'failed' do
        before { subject.fail! }

        it 'is failed' do
          expect(subject.state).to eq OrderPayment::STATE_FAILED
          expect(subject.order.admin_comments.auto.first.body).to eq I18n.t("order_payment_states_comments.#{OrderPayment::STATE_FAILED}")
        end
      end
    end

    shared_examples 'unfailable' do
      describe 'failed' do
        it 'raises error' do
          expect do
            subject.fail!
          end.to raise_error Workflow::NoTransitionAllowed
        end
      end
    end

    shared_examples 'payable' do
      describe 'paid' do
        before { subject.pay! }

        it 'is paid' do
          expect(subject.state).to eq OrderPayment::STATE_PAID
          expect(subject.order.admin_comments.auto.first.body).to eq I18n.t("order_payment_states_comments.#{OrderPayment::STATE_PAID}")
        end
      end
    end

    shared_examples 'unpayable' do
      describe 'paid' do
        it 'raises error' do
          expect do
            subject.pay!
          end.to raise_error Workflow::NoTransitionAllowed
        end
      end
    end

    shared_examples 'cancelable' do
      describe 'canceled' do
        before { subject.cancel! }

        it 'is canceled' do
          expect(subject.state).to eq OrderPayment::STATE_CANCELED
          expect(subject.order.admin_comments.auto.first.body).to eq I18n.t("order_payment_states_comments.#{OrderPayment::STATE_CANCELED}")
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

    describe 'await' do
      it_behaves_like 'failable'
      it_behaves_like 'payable'
      it_behaves_like 'cancelable'

      it do
        expect(subject.state_updated_at).to eq nil
        expect(subject.state).to eq OrderPayment::STATE_AWAIT
      end

      context 'transitions to paid' do
        it do
          expect_any_instance_of(OrderNotificationService).to receive(:order_paid)
          subject.pay!
        end
      end

      context 'payment received' do
        before { subject.order.order_payment.pay! }

        it 'changes state to paid' do
          expect(subject.reload.state).to eq OrderPayment::STATE_PAID
          expect(subject.reload.state_updated_at).to be_a ActiveSupport::TimeWithZone
        end
      end
    end

    describe 'direct' do
      before { subject.direct! }

      it_behaves_like 'unfailable'
      it_behaves_like 'payable'
      it_behaves_like 'cancelable'
      it { expect(subject.state).to eq OrderPayment::STATE_DIRECT }
    end

    describe 'failed' do
      before { subject.fail! }

      it_behaves_like 'failable'
      it_behaves_like 'payable'
      it_behaves_like 'cancelable'
      it { expect(subject.state).to eq OrderPayment::STATE_FAILED }
    end

    describe 'paid' do
      before { subject.pay! }

      it_behaves_like 'unfailable'
      it_behaves_like 'uncancelable'
      it { expect(subject.state).to eq OrderPayment::STATE_PAID }
    end

    describe 'canceled' do
      before { subject.cancel! }

      it_behaves_like 'failable'
      it { expect(subject.state).to eq OrderPayment::STATE_CANCELED }
    end
  end
end
