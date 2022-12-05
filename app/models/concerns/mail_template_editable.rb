module MailTemplateEditable
  def editable_content_html
    content_html.presence || default_content_html
  end

  def editable_content_text
    content_html.presence || default_content_text
  rescue Errno::ENOENT
    nil
  end

  def editable_content_text=(value)
    self.content_text = value
  end

  def editable_content_html=(value)
    self.content_html = value
  end

  def editable_content_sms
    content_sms.presence || default_content_sms
  end

  def editable_content_sms=(value)
    self.content_sms = value
  end
end
