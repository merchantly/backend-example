module VendorBells::VendorConcerns
  extend ActiveSupport::Concern

  included do
    has_many :bells, class_name: '::VendorBells::VendorBell' # -> { ordered }
  end

  def bells_handler
    @bells_handler ||= VendorBells::Dispatcher.new(vendor: self)
  end
end
