require 'rails_helper'

RSpec.describe 'Оплачивают тариф', :vcr, type: :feature, record: :once, sidekiq: :inline do
  let!(:cryptogram_packet) { '014111111111181202HMlHrKjZoDfj300GCMwu1NlQj+x/baxfWwq9ApgEBzHQwTsXRXxfegtFWd5tjHTkTbaKy7QXCiV5EKsPLJckEoS5thg9yS2+ardsWcNQNZdU2GJsneKgEcbSGeejTm+hRcM+ZI9kup05TTetGfqrvvgRgn/ShFd+z1K2XencOEivO1I6ySxlhXLCi894fPrWFh/9CGZSN7Pn7I/5FDPYNpOB1BwaqT7+6FqpFNM2XzZ/PCD3CqTdZALeYznXNjqKt/+G50k9gBp6pWgpCjH7lE/ALIwoqp2zgtD93bAwyaI9EdGxPdCx1h27HEcjJpnpl1IbORz6i1m77ZP0XRw6wA==' }
  let!(:vendor)            { create :vendor, working_to: nil }
  let!(:member)            { create :member, vendor: vendor }
  let!(:tariff)            { create :tariff }
  let!(:account)           { vendor.common_billing_account }

  def choice_tariff(tariff_id)
    # Страница выбора тарифа
    #
    visit operator_billing_path

    click_link 'Подключить', id: "tariff-#{tariff_id}"

    # Страница оплаты
    #
    invoice = OpenbillInvoice.last

    pay_invoice invoice
  end

  def click_and_pay_invoice(invoice)
    # Страница выбора тарифа
    #
    visit operator_billing_path

    # "<a class=\"btn-sm btn-warning\" target=\"_blank\" href=\"http://app.example.com/invoices/e0b91514-a575-4fc1-a72a-e5b4239c8e33\">Оплатить</a>\
    click_link href: "http://app.example.com/invoices/#{invoice.id}"

    pay_invoice invoice
  end

  def pay_invoice(invoice)
    expect(current_path).to include system_invoice_path(invoice)
    expect(page.body).to include invoice.title

    cloud_payments_transaction = build_stubbed :cloud_payments_transaction, invoice_id: invoice.id, account_id: account.id, amount: invoice.amount.to_f
    expect_any_instance_of(CloudPayments::Namespaces::Cards).to receive(:charge).and_return cloud_payments_transaction

    within '#new_cloud_payments_form' do
      fill_in 'cloud_payments_form_cardNumber', with: '4111111111111111'

      select '12', from: 'cloud_payments_form_expDateMonth'
      select (Date.current.year + 1).to_s, from: 'cloud_payments_form_expDateYear'

      fill_in 'cloud_payments_form_cvv', with: '123'
      fill_in 'cloud_payments_form_name', with: 'Автотест'

      fill_in_hidden 'cloud_payments_form[cryptogram_packet]', with: cryptogram_packet

      click_button 'Оплатить'
    end

    expect(page.body).to include 'Спасибо за оплату'
    expect(current_path).to include '/success'

    vendor.reload
  end

  # Сначала у магазина не установлен paid_to и working_to
  # Оператор нажал на оплату, оплатил, пришла транзация от cloudpayments
  # Это привело к том, что у магазина появился paid_to и working_to на месяц вперед

  it 'Новый магази на триале решил проплатить' do
    expect(vendor.paid_to).to be_nil
    expect(vendor.working_to).to be_nil
    expect(vendor.tariff).to be_nil

    choice_tariff tariff.id

    expect(vendor.tariff).to eq tariff
    expect(vendor.paid_to).not_to be_nil
    expect(vendor.working_to).not_to be_nil
    expect(vendor.paid_to).to be > Date.current
    expect(vendor.working_to).to be >= vendor.paid_to
  end

  context 'Уже работающий магазин' do
    let(:vendor) { create :vendor, working_to: working_to, paid_to: paid_to, tariff: tariff }
    let(:invoice) { Billing::Invoicer.create_next_month_invoice vendor: vendor }

    before do
      expect(vendor.paid_to).not_to be_nil
      expect(vendor.working_to).not_to be_nil
    end

    context 'На тарифе хочет его сменить' do
      let!(:paid_to)    { 5.days.ago.to_date }
      let!(:working_to) { paid_to + 15.days }
      let!(:new_tariff) { create :tariff }

      it 'После оплаты тариф меняется. paid_to устанавливается на месяц вперед' do
        choice_tariff new_tariff.id

        expect(vendor.tariff_id).to eq new_tariff.id
        expect(vendor.paid_to).to eq paid_to.next_month
        expect(vendor.working_to).to be >= vendor.paid_to
      end
    end

    context 'Оплачивает в промежутке между paid_to и working_to' do
      let!(:paid_to)    { 5.days.ago.to_date }
      let!(:working_to) { paid_to + 15.days }

      it 'paid_to устанавливается на месяц вперед' do
        click_and_pay_invoice invoice

        expect(vendor.paid_to).to eq paid_to.next_month.to_date
        expect(vendor.working_to).to be >= vendor.paid_to
      end
    end

    # TODO выбор кнопки оплаты счета вместо выбора тарифа

    context 'Оплачивает после working_to' do
      context 'Новый период полностью покрывает период до working_to и working_to не уведичивается' do
        let!(:paid_to)    { 90.days.ago.to_date }
        let!(:working_to) { paid_to + 60.days }

        before do
          expect(vendor.working_to).to be < Date.current
        end

        it 'После оплаты тариф меняется. paid_to устанавливается на месяц вперед' do
          click_and_pay_invoice invoice

          expect(vendor.paid_to).to eq paid_to.next_month
          expect(vendor.paid_to).to be < Date.current
          expect(vendor.working_to).to eq working_to
        end
      end
    end
  end
end
