#
# http://code.dblock.org/2011/09/09/rails-custom-and-editable-mailer-templates-in-markdown.html
#
require 'tilt'

class MailTemplate < ApplicationRecord
  include MailTemplateContextExample
  include MailTemplateEditable
  include MailTemplateRender
  include Authority::Abilities

  NAMESPACE_MERCHANT = 'merchant'.freeze
  NAMESPACE_CLIENT = 'client'.freeze
  NAMESPACES = [NAMESPACE_CLIENT, NAMESPACE_MERCHANT].freeze
  SHARED_METHODS = %i[new_order workflow_changed paid].freeze
  CLIENT_METHODS = SHARED_METHODS + %i[payment_link delivery_expired reminder_payment client_category_changed coupon]
  MERCHANT_METHODS = SHARED_METHODS + %i[run_out]
  NAMESPACE_KEYS = { client: CLIENT_METHODS, merchant: MERCHANT_METHODS }.freeze

  belongs_to :vendor

  validates :content_html, liquid: true
  validates :content_text, liquid: true
  validates :content_sms,  liquid: true
  validates :subject,      liquid: true

  validates :locale, presence: true

  validates :namespace, presence: true, inclusion: { in: NAMESPACES }

  validates :key,
            uniqueness: { scope: %i[vendor_id namespace locale] },
            presence: true

  validate :key_inclusion

  before_save :clear
  before_create do
    self.locale ||= vendor.default_locale
  end

  def self.namespace_keys(namespace)
    NAMESPACE_KEYS[namespace.to_sym]
  end

  def self.get(key:, namespace:, locale:)
    mt = find_or_initialize_by key: key, namespace: namespace, locale: locale
    mt.set_defaults
    mt
  end

  def allow_notification?(type)
    raise "Unknown type: #{type}" unless %i[email sms].include? type.to_sym

    send "allow_#{type}"
  end

  def to_s
    title
  end

  def title
    I18n.t key, scope: [:notifications, namespace]
  end

  def eval_subject(context)
    subject_template.render context.to_liquid, error_mode: error_mode
  end

  def to_html(context)
    html_template.render context.to_liquid, error_mode: error_mode
  end

  def to_sms(context)
    sms_template.render context.to_liquid, error_mode: error_mode
  end

  def to_text(context)
    text_template.render context.to_liquid, error_mode: error_mode
  end

  def to_param
    raise 'no namespace in mail_template' if namespace.blank?

    [namespace, key, locale].map(&:to_s) * ':'
  end

  def set_defaults
    self.subject      = default_subject if subject.blank?
    self.content_html = default_content_html if content_html.blank?
    self.content_text = default_content_text if content_text.blank?
    self.content_sms  = default_content_sms if content_sms.blank?
  end

  def error_mode
    :strict
  end

  private

  def clear
    self.subject      = nil if subject == default_subject
    self.content_html = nil if content_html == default_content_html
    self.content_text = nil if content_text == default_content_text
    self.content_sms  = nil if content_sms == default_content_sms
  end

  def key_inclusion
    errors.add :key, "Unknown key #{key}" unless Array(self.class.namespace_keys(namespace)).include? key.to_sym
  end
end
