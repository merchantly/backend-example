class MenuItemBlog < MenuItem
  def self.model_name
    superclass.model_name
  end

  def entity_title
    I18n.vt('auto_menu_items.blog')
  end

  def url
    Rails.application.routes.url_helpers.vendor_blog_index_path
  end
end
