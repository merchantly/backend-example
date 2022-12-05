class DefaultProductVatGroup < ApplicationRecord
  validates :country_code, presence: true
  validates :vat, presence: true

  def self.default
    find_by(is_default: true)
  end

  def self.create_groups!
    return if DefaultProductVatGroup.exists?

    Settings::DefaultVats.vat_percents.each do |country_code, percent|
      create!(country_code: country_code, vat: percent, is_default: false)
    end

    find_by(country_code: Settings::DefaultVats.default_country_code).update(is_default: true)
  end

  def self.find_by_country_code_or_default(country_code)
    find_by(country_code: country_code) || default
  end
end
