# оплата за включение каких то опций в операторской

module VendorPayOption
  extend ActiveSupport::Concern

  included do
    # снимаем оплату если вендор включил опцию "Отключить надпись сделано на киоске"
    after_save :pay_external_link_kiosk_disable, if: :need_pay_external_link_kiosk_disable?
    scope :external_link_kiosk_pay_day, -> { where('is_external_link_app_disabled = ? AND external_link_app_next_pay_date <= ?', true, Time.zone.today) }
  end

  private

  def pay_external_link_kiosk_disable
    Billing::ExternalLinkKioskFee.new(self).call
  end

  def need_pay_external_link_kiosk_disable?
    saved_change_to_is_external_link_app_disabled? && is_external_link_app_disabled &&
      (external_link_app_next_pay_date.nil? ||
        (external_link_app_next_pay_date.present? && DateTime.current >= external_link_kiosk_next_pay_date)
      )
  end
end
