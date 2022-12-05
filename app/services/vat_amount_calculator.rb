class VatAmountCalculator
  def initialize(vendor)
    @vendor = vendor
  end

  def perform(price:, vat:)
    float_vat = vat.to_f

    return vendor.zero_money if price.to_f.zero? || float_vat.zero?

    if vat_inclusive?
      (price * float_vat) / (100 + float_vat)
    else
      price * float_vat / 100.0
    end
  end

  def vat_inclusive?
    case vendor.vat_calculation_version.to_sym
    when :v1
      false
    when :v2
      true
    else
      raise "Unknown #{vendor.vat_calculation_version}"
    end
  end

  def self.vat_inclusive?(vendor)
    new(vendor).vat_inclusive?
  end

  private

  attr_reader :vendor
end
