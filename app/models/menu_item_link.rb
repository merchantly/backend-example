class MenuItemLink < MenuItem
  validates :link_url, presence: true, url: true, length: { maximum: 250 }

  def self.model_name
    superclass.model_name
  end

  def target_blank?
    true
  end

  def title
    custom_title.presence || "link#{id}"
  end

  def url
    link_url
  end

  def entity_title
    if link_url.present?
      Addressable::URI.parse(link_url.to_s).host || link_url.to_s
    elsif persisted?
      "unknown_#{id}"
    else
      ''
    end
  rescue StandardError
    ''
  end
end
