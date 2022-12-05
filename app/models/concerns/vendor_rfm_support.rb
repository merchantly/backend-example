module VendorRfmSupport
  def rfm_segments(force = false)
    if force
      if vendor_rfm.present?
        vendor_rfm.rebuild!
      else
        create_vendor_rfm(RFMAnalytics::SegmentsBuilder.new(vendor: self).build.to_h)
      end
    else
      vendor_rfm || create_vendor_rfm(RFMAnalytics::SegmentsBuilder.new(vendor: self).build.to_h)
    end
  end
end
