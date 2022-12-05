class ExchangeRate < ApplicationRecord
  UnknownRate = Class.new StandardError

  # Чтобы работало Money.new(123).to_json
  def self.as_json(*_args)
    { name: name }
  end

  # def self.collection
  # @collection ||= (pluck(:from) + pluck(:to)).uniq.sort.map do |cur|
  # title = "#{cur} (#{Money::Currency.find(cur).try(:name)})"
  # [title, cur]
  # end
  # end

  def self.get_rate(from_iso_code, to_iso_code)
    rate = find_by(from: from_iso_code, to: to_iso_code, vendor_id: nil) || raise(UnknownRate, "Не найден курс #{from_iso_code} -> #{to_iso_code}")
    rate.rate
  end

  def self.get_rate!(from_iso_code, to_iso_code)
    get_rate(from_iso_code, to_iso_code)
  rescue UnknownRate
    1.0 / get_rate(to_iso_code, from_iso_code)
  end

  def self.rate_exists?(from_iso_code, to_iso_code)
    get_rate(from_iso_code, to_iso_code).present?
  rescue UnknownRate
    false
  end

  def self.add_rate(from_iso_code, to_iso_code, rate, comment: nil)
    exrate = find_or_initialize_by(from: from_iso_code, to: to_iso_code, vendor_id: nil)
    exrate.comment = comment
    exrate.rate = rate
    exrate.save!

    exrate = find_or_initialize_by(from: to_iso_code, to: from_iso_code, vendor_id: nil)
    exrate.comment = comment
    exrate.rate = 1.0 / rate
    exrate.save!
  end
end
