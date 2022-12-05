class VatAmountAccumulator
  def initialize(vendor)
    @calculator = VatAmountCalculator.new(vendor)
    @amount = vendor.zero_money
  end

  def add(price, vat_percent)
    return if vat_percent.to_f.zero? || price.to_f.zero?

    @amount += calculator.perform(price: price, vat: vat_percent)
  end

  def result
    @amount
  end

  private

  attr_reader :calculator
end
