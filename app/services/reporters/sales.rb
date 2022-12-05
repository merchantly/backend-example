class Reporters::Sales < Reporters::SalesBase
  class Report
    include Virtus.model
    attribute :total_price
    attribute :total_vat
    attribute :total_purchase_price
    attribute :items
  end

  class SalesReportItem
    include Virtus.model

    attribute :article
    attribute :title
    attribute :public_url
    attribute :cached_vat
    attribute :price
    attribute :total_price
    attribute :vat
    attribute :total_purchase_price
    attribute :quantity
    attribute :good_id
    attribute :category_id
  end

  def perform
    Report.new(
      items: build_items,
      total_price: @total_price,
      total_vat: @total_vat,
      total_purchase_price: @total_purchase_price
    )
  end

  private

  delegate :zero_money, to: :vendor

  def build_items
    @cached_items = {}
    @total_price = zero_money
    @total_vat = zero_money
    @total_purchase_price = zero_money

    return [] if order_items.empty?

    order_items.each do |oi|
      build_item oi
    end

    @cached_items.values.map { |item| SalesReportItem.new item }
  end

  def build_item(oi)
    key = [oi.title, oi.good_type, oi.good_id, oi.cached_vat, oi.price, oi.selling_by_weight?].join('-')

    item = @cached_items[key] ||= {
      article: oi.good.try(:article),
      title: oi.title,
      public_url: oi.good.try(:public_url),
      cached_vat: oi.cached_vat,
      price: oi.price,
      total_price: zero_money,
      vat: zero_money,
      total_purchase_price: zero_money,
      quantity: 0,
      good_id: oi.good.try(:id),
      category_id: oi.good.try(:category_id)
    }

    item[:quantity] += oi.smart_quantity
    item[:total_price] += oi.total_price
    item[:total_purchase_price] += oi.total_purchase_price if oi.total_purchase_price.present?
    item[:vat] += oi.vat if oi.vat.present?

    @total_price += oi.total_price
    @total_purchase_price += oi.total_purchase_price if oi.total_purchase_price.present?
    @total_vat += oi.vat if oi.vat.present?
  end
end
