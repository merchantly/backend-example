class Vendor
  module PartnerSupport
    extend ActiveSupport::Concern

    included do
      before_save :perform_partner_coupon
    end

    private

    def perform_partner_coupon
      return if partner_coupon_code.blank? || partner_coupon.present?

      self.partner_coupon = ::Partner::Coupon.find_by(code: partner_coupon_code)
      self.partner_coupon_active_to = Date.current + partner_coupon.active_days.days if partner_coupon.present? && !partner_coupon.perpetual?
      true
    end
  end
end
