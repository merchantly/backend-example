class CouponsSpreadsheet < AbstractBaseSpreadsheet
  FIELDS = %w[code use_count used_count discount discount_type expires_at].freeze

  private

  def header_row
    FIELDS.map { |f| Client.human_attribute_name f }
  end

  def row(coupon)
    FIELDS.map do |f|
      coupon.send f
    end
  end
end
