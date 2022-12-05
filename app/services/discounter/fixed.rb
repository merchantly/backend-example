module Discounter
  class Fixed < Base
    def perform
      if satisfy?
        Discounting.new(
          discount: 0,
          free_delivery: coupon.free_delivery?,
          discount_price: total_price - total_discounted,
          total_discounted: total_discounted,
          total_vat_price: vat_amount_accumulator.result
        )
      else
        Discounting.new(
          discount: 0,
          free_delivery: false,
          discount_price: vendor.zero_money,
          total_discounted: items_price + package_price,
          total_vat_price: total_vat_price + package_vat_price
        )
      end
    end

    private

    def total_price
      @total_price ||= items_price + package_price
    end

    def total_discounted
      @total_discounted ||= build_total_discounted
    end

    def build_total_discounted
      total_items_price = 0
      total_discount_price = coupon.discount_price

      items.each do |item|
        if satisfy_product_behavior?(item.product) && satisfy_category_behavior?(item.product) && (total_discount_price > vendor.zero_money)
          if total_discount_price >= item.total_price
            total_discount_price -= item.total_price
          else
            item_total_price = item.total_price - total_discount_price
            total_items_price += item_total_price

            vat_amount_accumulator.add total_items_price, item.vat_percent

            total_discount_price = vendor.zero_money
          end
        else
          total_items_price += item.total_price
          vat_amount_accumulator.add item.total_price, item.vat_percent
        end
      end

      if coupon.is_discounting_package? && (total_discount_price > vendor.zero_money)
        if total_discount_price < package_price
          discounted_package_price = package_price - total_discount_price
          total_items_price += discounted_package_price

          vat_amount_accumulator.add discounted_package_price, package_good.try(:vat)
        end
      else
        total_items_price += package_price

        vat_amount_accumulator.add package_price, package_good.try(:vat)
      end

      total_items_price
    end

    def satisfy?
      return true if for_all?

      items.each do |item|
        return true if satisfy_product_behavior?(item.product) && satisfy_category_behavior?(item.product)
      end

      false
    end
  end
end
