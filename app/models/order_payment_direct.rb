class OrderPaymentDirect < OrderPayment
  before_create :set_state

  def template
    if payment_type.content.present?
      TEMPLATE_CUSTOM
    else
      TEMPLATE_CREATED
    end
  end

  def reset_state!
    direct! unless direct?
  end

  private

  def set_state
    self.state = 'direct'
  end
end
