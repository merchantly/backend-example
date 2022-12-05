class VendorExchangeRate < ExchangeRate
  belongs_to :vendor

  def self.vendor_id
    Thread.current[:vendor].try :id
  end

  def self.get_rate(from_iso_code, to_iso_code)
    rate = find_by(from: from_iso_code, to: to_iso_code, vendor_id: vendor_id) if vendor_id.present?
    rate.try(:rate) || super
  end

  def self.add_rate(from_iso_code, to_iso_code, rate, comment: nil)
    exrate = find_or_initialize_by(from: from_iso_code, to: to_iso_code, vendor_id: vendor_id)
    exrate.comment = comment
    exrate.rate = rate
    exrate.save!

    exrate = find_or_initialize_by(from: to_iso_code, to: from_iso_code, vendor_id: vendor_id)
    exrate.comment = comment
    exrate.rate = 1.0 / rate
    exrate.save!
  end
end
