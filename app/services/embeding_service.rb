class EmbedingService
  include Virtus.model

  attribute :video_url, String

  YOUTUBE_PATTERN = /youtube.com\/watch/.freeze
  SHORT_YOUTUBE_PATTERN = /youtu\.be/.freeze
  VIDEO_URL_PATTERNS = [YOUTUBE_PATTERN, SHORT_YOUTUBE_PATTERN].freeze

  def perform
    case video_url
    when YOUTUBE_PATTERN
      youtube_html parse_youtube_watch video_url
    when SHORT_YOUTUBE_PATTERN
      youtube_html parse_youtube_short video_url
    else
      Bugsnag.notify 'Не известный формат для встраивания',
                     metaData: { video_url: video_url },
                     severity: :warning
      ''
    end
  end

  private

  attr_reader :product

  # https://youtu.be/7Ypi5HHbhsQ
  def parse_youtube_short(video_url)
    a = Addressable::URI.parse video_url
    a.path.tr '/', ''
  end

  # https://www.youtube.com/watch?v=4MdefpBbEn4
  def parse_youtube_watch(video_url)
    a = Addressable::URI.parse video_url
    a.query_values['v']
  end

  def youtube_html(v)
    url = "https://www.youtube.com/embed/#{v}?rel=0&showinfo=0"
    "<div style=\"left: 0; width: 100%; height: 0; position: relative; padding-bottom: 56.2493%;\"><iframe src=\"#{url}\" style=\"border: 0; top: 0; left: 0; width: 100%; height: 100%; position: absolute;\" allowfullscreen scrolling=\"no\"></iframe></div>".html_safe
  end

  # Отключил iframe потому что жалко денег
  #
  def iframe_html
    Rails.cache.fetch Addressable::URI.escape(product.active_video_url) do
      json = $iframely.get_iframely_json product.active_video_url

      if json.present? && json.is_a?(Hash)
        json['html']
      else
        nil
      end
    end.to_s.html_safe
  rescue StandardError => e
    Bugsnag.notify e, metaData: { product_id: product.id, video_url: product.active_video_url }
    e.message
  end
end
