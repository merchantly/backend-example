module CustomDescriptionHstore
  extend ActiveSupport::Concern

  def description=(val)
    self.custom_description = val
  end

  def description
    cached_description
  end
end
