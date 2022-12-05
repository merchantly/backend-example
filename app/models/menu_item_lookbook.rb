class MenuItemLookbook < MenuItem
  validates :lookbook_id, presence: true

  def self.model_name
    superclass.model_name
  end

  def entity_title
    lookbook.try :title
  end

  def entity
    lookbook
  end

  def url
    lookbook.try :public_path
  end
end
