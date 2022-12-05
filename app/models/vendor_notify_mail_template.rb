# класс для редактирования шаблонов уведомлений магазинов

class VendorNotifyMailTemplate < SystemMailTemplate
  # уведомление о том что магазин будет перенесен в архив если им не начнут пользоваться(оплатят)
  TYPE_SHOP_WILL_ARCHIVE = 'notify_shop_will_archive'.freeze
  TYPE_VENDOR_ARCHIVE = 'vendor_archived'.freeze

  TYPES = [TYPE_SHOP_WILL_ARCHIVE, TYPE_VENDOR_ARCHIVE].freeze

  enumerize :template_type, in: TYPES

  def self.get(key:, locale:)
    mt = find_or_initialize_by template_type: key
    mt.set_defaults(locale) unless mt.persisted?
    mt
  end

  def context_example
    @context_example ||= VendorNotifyMailContext.new operator: example_operator, vendor: example_vendor, template: self
  end

  def set_defaults(locale)
    self.subject = I18n.t("vendor_mailer.#{template_type}.subject")
    self.content = File.read(Rails.root.join('app/views/operator_mail_templates', locale.to_s, "#{template_type}.html.liquid"))
  end

  private

  def example_vendor
    Vendor.new(subdomain: 'test')
  end
end
