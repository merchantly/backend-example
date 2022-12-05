module ProductVideo
  extend ActiveSupport::Concern

  included do
    validates :video_url, url: { allow_blank: true }

    validate :validate_video_url, if: :video_url
  end

  def video_embed_html
    EmbedingService.new(video_url: video_url).perform if video_url.present?
  end

  private

  def validate_video_url
    if EmbedingService::VIDEO_URL_PATTERNS.map { |p| p =~ video_url }.compact.blank?
      errors.add :video_url, I18n.t('errors.messages.embeding_url_invalid', patterns: EmbedingService::VIDEO_URL_PATTERNS.map(&:to_s).join(', '))
    end
  end
end
