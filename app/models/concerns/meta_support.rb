module MetaSupport
  extend ActiveSupport::Concern

  included do
    validate :validate_meta!
  end

  def meta
    value = parse_meta super
    Meta.new(value).freeze
  rescue StandardError
    super
  end

  private

  def validate_meta!
    value = self[:meta]
    return unless value.is_a? String

    self.meta = parse_meta value
  rescue StandardError => e
    errors.add :meta, e
  end

  def parse_meta(value)
    return value unless value.is_a? String

    JSON.parse value
  end
end
