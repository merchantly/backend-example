module GenerateKey
  extend ActiveSupport::Concern
  KEY_TRANSLATIONS = { ves: :weight, razmer: :size, tsvet: :color }.freeze

  included do
    scope :by_key, ->(key) { where key: key }

    before_validation :generate_key
    validates :key, presence: true, uniqueness: { scope: :vendor_id }
    validate :key_not_changed
  end

  private

  def generate_key
    return if key.present?
    return if vendor.blank?

    vendor.with_lock do
      source = title.presence || SecureRandom.hex
      self.key = Russian.translit(source).downcase.parameterize.underscore
      self.key = KEY_TRANSLATIONS[key] if KEY_TRANSLATIONS.include? key
      self.key = "#{key}_#{SecureRandom.hex}" if self.class.exists?(vendor_id: vendor.id, key: key)
    end
  end

  def key_not_changed
    if will_save_change_to_key? && persisted?
      errors.add(:key, I18n.t('activerecord.errors.property.attributes.key.unchangable'))
    end
  end
end
