module MailTemplateRender
  def default_content_html
    File.read default_template 'html'
  end

  def default_content_text
    premailer = Premailer.new default_template('html')
    premailer.to_plain_text
  end

  def default_content_sms
    File.read default_template 'sms'
  end

  def default_subject
    I18n.t key, scope: "order_mailer.#{namespace}.subjects"
  end

  def default_sms
    content_sms.presence || default_content_sms
  end

  private

  def subject_content
    subject || default_subject
  end

  def subject_template
    Liquid::Template.parse subject_content
  end

  def sms_template
    if content_sms.present?
      Liquid::Template.parse content_sms
    else
      Tilt.new default_template 'sms'
    end
  end

  def html_template
    if content_html.present?
      Liquid::Template.parse content_html
    else
      Tilt.new default_template 'html'
    end
  end

  def text_template
    if content_text.present?
      Liquid::Template.parse content_text
    else
      Tilt.new default_template 'text'
    end
  end

  def default_template(type = 'html')
    raise 'no namespace in mail_template' if namespace.blank?

    File.exist?(localized_template(type)) ? localized_template(type) : default_locale_template(type)
  end

  def localized_template(type = 'html')
    Rails.root.join('app/views/mail_templates', locale, namespace, "#{key}.#{type}.liquid")
  end

  def default_locale_template(type = 'html')
    Rails.root.join('app/views/mail_templates', I18n.default_locale, namespace, "#{key}.#{type}.liquid")
  end
end
