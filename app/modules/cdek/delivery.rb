class Cdek::Delivery < ApplicationRecord
  CURRENCY = 'RUB'.freeze

  self.table_name = :cdek_deliveries

  belongs_to :vendor_delivery

  has_many :orders, dependent: :nullify, foreign_key: 'cdek_delivery_id'

  def title
    return @title if @title.present?

    @title = "#{cost} р."

    if home?
      @title << ", #{city}"
      @title << ", #{obl_name}" if obl_name.present?
      @title << " (#{country})"
    elsif pickup_point?
      @title << ", #{address}, #{work_time}"
    end

    @title
  end

  def price
    @price ||= Money.new (cost * 100), CURRENCY
  end

  private

  def home?
    Cdek::HOME_TARIFFS.include?(tariff_id)
  end

  def pickup_point?
    Cdek::PICKUP_POINT_TARIFFS.include?(tariff_id)
  end
end
