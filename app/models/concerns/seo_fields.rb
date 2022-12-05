module SeoFields
  extend ActiveSupport::Concern

  SEO_FIELDS = %w[h1 meta_title meta_description meta_keywords].freeze

  included do
    before_save :sanitize_seo_fields
  end

  def sanitize_seo_fields
    SEO_FIELDS.each do |f|
      send("#{f}=", Rails::Html::Sanitizer.full_sanitizer.new.sanitize(send(f))) if send("#{f}_changed?")
    end
  end
end
