module CustomTitleHstore
  extend ActiveSupport::Concern

  def title=(val)
    self.custom_title = val
    self.cached_title = val
  end

  def title
    cached_title
  end
end
