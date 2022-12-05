module SystemMailTemplateContextExample
  def context_example
    @context_example ||= SystemMailContext.new(
      template: self,
      operator: operator,
      vendor: vendor,
      recipient: example_recipient,
      invoice: OpenbillInvoice.new(id: 'test-uid', amount: Money.new(1000), number: 'test-invoice', title: 'Тестовый счет').freeze,
      is_example: true
    )
  end

  def context_example_to_validate
    @context_example_to_validate ||= SystemMailContext.new(
      is_example: true,
      template: self,
      operator: operator,
      vendor: vendor,
      invoice: OpenbillInvoice.new(id: 'test-uid', amount: Money.new(1000), number: 'test-invoice', title: 'Тестовый счет').freeze,
      recipient: SystemMailRecipient.new(
        system_mail_template: self,
        vendor: vendor,
        operator: operator,
        delivery: nil
      ).freeze
    )
  end

  private

  def operator
    example_operator || example_vendor.try(:operators).try(:first) || Operator.first
  end

  def vendor
    example_vendor || Vendor.demo
  end

  def example_recipient
    @example_recipient ||= create_system_mail_recipient
  end

  def create_system_mail_recipient
    SystemMailRecipient
      .find_or_create_by!(
        system_mail_template: self,
        vendor: vendor,
        operator: operator,
        delivery: example_delivery
      )
  end

  def example_delivery
    SystemMailDelivery.create_with(title: "auto preview: #{title}")
      .find_or_create_by!(
        state: SystemMailDelivery::STATE_PREVIEW,
        system_mail_template: self
      )
  end

  # def demo_operator
  # return self.example_operator if respond_to?(:example_operator) && example_operator.present?
  # demo_vendor.operators.first || Operator.first
  # end

  # def demo_vendor
  # return self.example_vendor if respond_to?(:example_vendor) && example_vendor.present?
  # Vendor.demo
  # end
end
