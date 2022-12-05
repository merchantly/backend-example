module CachedTitle
  extend ActiveSupport::Concern

  included do
    scope :by_title, ->(title) { where cached_title: title }
    before_save :cache_title
  end

  private

  def cache_title
    self.cached_title = title
  end
end
