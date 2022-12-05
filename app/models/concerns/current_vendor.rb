module CurrentVendor
  NoCurrentVendor = Class.new StandardError

  def current_vendor
    if respond_to? :vendor_id
      if Thread.current[:vendor].present? && Thread.current[:vendor].id == vendor_id
        Thread.current[:vendor]
      else
        if respond_to? :vendor
          vendor
        else
          raise NoCurrentVendor
        end
      end
    elsif Thread.current[:vendor].present?
      Thread.current[:vendor]
    else
      raise NoCurrentVendor
    end
  end

  def model_vendor
    current_vendor if vendor_id.present? && current_vendor.id == vendor_id
  end

  def set_current_vendor(vendor)
    Thread.current[:vendor] = vendor
  end

  def safe_current_vendor
    current_vendor
  rescue NoCurrentVendor
    nil
  end
end
