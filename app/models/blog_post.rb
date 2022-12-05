class BlogPost < ApplicationRecord
  include Authority::Abilities
  include Archivable
  include Activable
  include CurrentVendor
  include Droppable
  include Slugable
  include SeoFields
  include RoutesConcern
  include RecommendedProducts

  belongs_to :vendor, counter_cache: true

  scope :ordered, -> { order published_at: :desc }
  scope :reverse_ordered, -> { order published_at: :asc }

  validates :title, presence: true
  validates :url, url: { allow_blank: true }

  before_create :set_published_at

  translates :title, :content, :short_text

  mount_uploader :image, ImageUploader

  # для meta
  def description
    content
  end

  def prev_post
    vendor.blog_posts.alive.active.ordered.find_by('published_at < ?', published_at)
  end

  def next_post
    vendor.blog_posts.alive.active.reverse_ordered.find_by('published_at > ?', published_at)
  end

  def header_url(params = {})
    if url.present?
      params = params.to_query
      params.present? ? "?#{params}" : ''
      url + params
    else
      public_url params
    end
  end

  def default_path(params = {})
    vendor_blog_path to_param, params
  end

  private

  def set_published_at
    self.published_at ||= Time.zone.now
  end
end
