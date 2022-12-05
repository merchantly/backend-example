module ProductGoods
  extend ActiveSupport::Concern

  # Все товары проданы
  # TODO кешировать is_run_out в модели ProductItem
  # TODO кешировать is_sold в модели Product
  def is_sold
    goods.all?(&:is_run_out)
  end

  def goods
    if ordering_as_product_only?
      [self]
    else
      i = items.alive
      return i if i.one?

      items.alive.ordered.exclude_default
    end
  end

  def ordering_goods
    @ordering_goods ||= goods.select(&:is_ordering)
  end

  def goods_include_me(scope = nil)
    if ordering_as_product_only?
      [self]
    else
      base_scope = items.alive.exclude_default
      base_scope = base_scope.select(&:is_ordering) if scope == :in_stock
      base_scope.to_a + [self]
    end
  end
end
