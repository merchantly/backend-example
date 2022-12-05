module VendorVatCategory
  extend ActiveSupport::Concern

  VAT_CATEGORIES = %w[S E Z].freeze
  DEFAULT_VAT_CATEGORY = 'S'.freeze

  E_REASONS = %w[
    VATEX-SA-29
    VATEX-SA-29-7
    VATEX-SA-30
  ].freeze

  Z_REASONS = %w[
    VATEX-SA-32
    VATEX-SA-33
    VATEX-SA-34-1
    VATEX-SA-34-2
    VATEX-SA-34-3
    VATEX-SA-34-4
    VATEX-SA-34-5
    VATEX-SA-35
    VATEX-SA-36
    VATEX-SA-EDU
    VATEX-SA-HEA
  ].freeze

  REASONS = E_REASONS + Z_REASONS

  included do
    enumerize :vat_category, in: VAT_CATEGORIES, default: DEFAULT_VAT_CATEGORY
    enumerize :reason, in: REASONS

    validate :validate_reason, if: :reason

    before_validation do
      self.reason = nil if vat_category == 'S'
    end
  end

  private

  def validate_reason
    errors.add :reason, 'asdf' unless available_reasons.include?(reason)
  end

  def available_reasons
    case vat_category.to_sym
    when :E
      E_REASONS
    when :Z
      Z_REASONS
    when :S
      []
    else
      raise "Unknown #{vat_category}"
    end
  end
end
