module Vendor::Services
  extend ActiveSupport::Concern

  included do
    has_many :vendor_services
  end

  def prolongate!(days = 7)
    new_working_to = Date.current + days.days
    update_attribute :working_to, new_working_to if working_to.nil? || new_working_to > working_to
  end

  def service(key)
    openbill_service = OpenbillService.find_by_key!(key)
    vendor_services.find_or_create_by(openbill_service: openbill_service)
  end
end
