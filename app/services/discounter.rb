module Discounter
  class Base
    include Virtus.model strict: true

    attribute :coupon, Coupon
    attribute :items, Array # CartItem or OrderItem
    attribute :package_good
    attribute :package_count

    private

    delegate :vendor, :fixed_discount, :free_delivery?, :empty?, :product_ids, :category_ids, :for_all?, :satisfy_product_behavior?, :satisfy_category_behavior?,
             to: :coupon

    def vat_amount_accumulator
      @vat_amount_accumulator ||= VatAmountAccumulator.new(vendor)
    end

    def total_vat_price
      @total_vat_price ||= (items.map(&:vat_amount).compact.inject(:+) || vendor.zero_money) + package_vat_price
    end

    def package_vat_price
      @package_vat_price ||= VatAmountCalculator.new(vendor).perform(price: package_price, vat: package_good.try(:vat))
    end

    def total_discounted_vat_price
      @total_discounted_vat_price ||= total_vat_price + package_vat_price
    end

    def package_price
      @package_price ||= package_good.present? ? (package_good.price * package_count) : vendor.zero_money
    end

    def items_price
      @items_price ||= items.map(&:total_price).compact.inject(:+) || vendor.zero_money
    end

    def item_product_ids
      @item_product_ids ||= items.map { |i| i.product.id }.compact
    end

    def item_category_ids
      @item_category_ids ||= items.map { |i| i.product.categories_path_ids }.flatten
    end

    def item_category_included?(item)
      (item.product.categories_path_ids & category_ids).any?
    end
  end
end
