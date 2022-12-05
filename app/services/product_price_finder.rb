class ProductPriceFinder
  include Virtus.model

  attribute :good # Product, ProductItem
  attribute :client_category, ClientCategory

  def perform
    if good.is_sale?
      sale_price = available_prices.find { |pp| pp.price_kind == sale_price_kind }

      return sale_price if sale_price.present?
    end

    founded_price = available_prices.delete_if { |pp| pp.price_kind == sale_price_kind }.min_by { |pp| pp.price_cents }

    founded_price.presence
  end

  private

  def available_prices
    @available_prices ||= build_available_prices
  end

  def build_available_prices
    product_prices = case good
                     when Product
                        good.product_prices.where(price_kind_id: avialable_price_kinds.pluck(:id)).to_a
                     when ProductItem
                        avialable_price_kinds.map do |price_kind|
                          good.product_prices.with_price.find_by(price_kind: price_kind) || good.product.product_prices.find_by(price_kind: price_kind)
                        end.compact
                      end

    product_prices.select { |pp| pp.price_cents.to_f.positive? }
  end

  def avialable_price_kinds
    @avialable_price_kinds ||= client_category.available_price_kinds
  end

  def sale_price_kind
    @sale_price_kind ||= good.vendor.sale_price_kind
  end
end
