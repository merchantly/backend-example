class TaxCalculator
  include Virtus.model

  attribute :price, Money, require: true
  attribute :vendor, Vendor, require: true

  def perform
    case vendor.tax_type
    when nil, 'tax_ru_1', 'tax_ru_2'
      0
    when 'tax_ru_3'
      price * 10 / 100
    when 'tax_ru_4'
      price * 18 / 100
    when 'tax_ru_5'
      price * 10 / 110
    when 'tax_ru_6'
      price * 18 / 118
    else
      raise "Не известный тип налогоблажения #{vendor.tax_type} у магазина #{vendor.id}"
    end
  end
end
