module Discounter
  class Percent < Base
    def perform
      if satisfy?
        Discounting.new(
          free_delivery: coupon.free_delivery?,
          discount: coupon.discount,
          discount_price: total_price - total_discounted,
          total_discounted: total_discounted,
          total_vat_price: vat_amount_accumulator.result
        )
      else
        Discounting.new(
          free_delivery: false,
          discount: 0,
          discount_price: vendor.zero_money,
          total_discounted: total_price,
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
      discounted_items_price + discounted_package_price
    end

    def discounted_package_price
      if coupon.is_discounting_package?
        discounted_package_price = discounted_price(package_price)

        vat_amount_accumulator.add discounted_package_price, package_good.try(:vat)

        discounted_package_price
      else
        vat_amount_accumulator.add package_price, package_good.try(:vat)

        package_price
      end
    end

    # Цена со скидкой для линкованного купона
    def discounted_items_price
      total_items_price = vendor.zero_money

      items.each do |item|
        if satisfy_product_behavior?(item.product) && satisfy_category_behavior?(item.product)
          item_total_price = discounted_price(item.total_price)
          total_items_price += item_total_price

          vat_amount_accumulator.add item_total_price, item.vat_percent
        else
          total_items_price += item.total_price

          vat_amount_accumulator.add item.total_price, item.vat_percent
        end
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

    # Цена со скидкой
    def discounted_price(price)
      dp = (price * coupon.discount / 100).exchange_to price.currency
      return vendor.zero_money if dp >= price

      price - dp
    end
  end
end
