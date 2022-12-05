require 'i18n/backend/active_record'

class Translation < I18n::Backend::ActiveRecord::Translation
  include Authority::Abilities

  belongs_to :vendor, touch: :translations_updated_at

  scope :by_vendor, ->(vendor) { where vendor_id: vendor.id }

  before_save :strip_value

  def to_param
    if persisted?
      super
    else
      "#{locale}:#{key}"
    end
  end

  def custom?
    value != default_value
  end

  def custom_value
    if custom?
      value
    else
      ''
    end
  end

  def anchor
    "translation_#{id || key}"
  end

  def default_value
    @default_value ||= fallback_backend.translate locale, "vendor.#{key}"
  end

  def is_proc
    false
  end

  private

  def fallback_backend
    I18n::Backend::Simple.new
  end

  def strip_value
    return if value.blank?

    self.value = value.strip
  end
end
