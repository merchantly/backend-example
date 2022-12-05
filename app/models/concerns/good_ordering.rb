module GoodOrdering
  # TODO Кешировать в таблице
  delegate :is_ordering, :is_run_out, :ordering_quantity_state, :has_price, to: :ordering_state

  delegate :sellable_infinity?, to: :vendor

  def is_preorder
    false
  end

  def ordering_state
    ordering_service.state
  end

  def ordering_service
    @ordering_service = ProductOrderingService.new(self)
  end
end
