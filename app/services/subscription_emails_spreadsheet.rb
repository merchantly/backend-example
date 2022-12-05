class SubscriptionEmailsSpreadsheet < AbstractBaseSpreadsheet
  FIELDS = %w[email created_at].freeze

  private

  def encoding
    'cp1251'
  end

  def header_row
    FIELDS.map { |f| SubscriptionEmail.human_attribute_name f }
  end

  def row(subscription_email)
    [
      subscription_email.email,
      I18n.l(subscription_email.created_at, format: :amo_csv)
    ]
  end
end
