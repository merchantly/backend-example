class VendorRfm < ApplicationRecord
  belongs_to :vendor

  monetize :max_total_orders_price_cents, as: :max_total_orders_price
  monetize :min_total_orders_price_cents, as: :min_total_orders_price

  # TODO
  # validate что r,f,m идут сверху вниз

  def rebuild!
    update!(
      RFMAnalytics::SegmentsBuilder.new(vendor: vendor).build.to_h
    )
  end

  def moneys
    @moneys ||= m.map { |v| Money.new(v, max_total_orders_price_currency).exchange_to vendor.default_currency }
  end

  def recencies
    r
  end

  def frequencies
    f
  end
end
