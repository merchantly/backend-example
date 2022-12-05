module VendorUtm
  def init_utm=(value)
    self.init_utm_source   = value.utm_source
    self.init_utm_campaign = value.utm_campaign
    self.init_utm_medium   = value.utm_medium
    self.init_utm_term     = value.utm_term
    self.init_utm_content  = value.utm_content
  end

  def last_utm=(value)
    self.last_utm_source   = value.utm_source
    self.last_utm_campaign = value.utm_campaign
    self.last_utm_medium   = value.utm_medium
    self.last_utm_term     = value.utm_term
    self.last_utm_content  = value.utm_content
  end

  def referer
    last_referer.presence || init_referer
  end

  def init_utm
    UtmEntity.build attributes, :init_
  end

  def last_utm
    UtmEntity.build attributes, :last_
  end
end
