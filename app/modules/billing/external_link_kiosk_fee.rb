# списание платы за отключение надписи "сделано на киоске"

module Billing
  class ExternalLinkKioskFee
    attr_reader :vendor

    def initialize(vendor)
      @vendor = vendor
    end

    def call
      ActiveRecord::Base.transaction do
        make_transaction
        vendor.update_column :external_link_app_next_pay_date, (DateTime.current + 1.month).to_date
      end
    end

    private

    def make_transaction
      OpenbillTransaction.create!(
        from_account: vendor.common_billing_account,
        to_account_id: Billing::EXTERNAL_LINK_KIOSK_ACCOUNT_ID,
        key: [:external_link_kiosk_disable, vendor.id, date.year, date.month].join(':'),
        amount: amount,
        details: 'Отключение надписи "Сделано на Киоске"',
        date: date,
        meta: {
          workflow: :external_link_kiosk,
          day: date.day,
          month: date.month,
          year: date.year,
          tariff_id: vendor.tariff.id
        }
      )
    end

    def amount
      vendor.tariff.link_app_disable_price
    end

    def date
      @date ||= DateTime.current
    end
  end
end
