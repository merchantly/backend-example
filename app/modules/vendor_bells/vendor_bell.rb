class VendorBells::VendorBell < ApplicationRecord
  include LoadedUrl
  include VendorBellRead
  include Authority::Abilities

  MAIL_DELAY = 15.minutes

  belongs_to :vendor

  scope :ordered, -> { order id: :desc }

  validates :key, presence: true

  after_commit on: :create do
    # TODO Использовать VendorNotificationService
    # VendorMailer.bell(id).deliver_later!(wait: MAIL_DELAY)
  end

  def image_url
    Settings.favicon
  end

  def url
    loaded_url(Settings::Bells.url[key] || 'operator_bells_path')
  end

  def text
    t :text, options.to_s
  end

  def subject
    t :subject, key
  end

  private

  def t(t_key, default = nil)
    I18n.t t_key, options.symbolize_keys.reverse_merge(scope: [:bells, key], default: default)
  end
end
