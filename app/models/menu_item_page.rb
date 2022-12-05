class MenuItemPage < MenuItem
  validates :content_page_id, presence: true

  def self.model_name
    superclass.model_name
  end

  def entity_title
    content_page.try :title
  end

  def entity
    content_page
  end

  def url
    content_page.try :public_path
  end
end
