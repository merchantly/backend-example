class ClearAccounts
  SUBJECT = 'Упс! Это была ошибка, ничего платить не надо!'.freeze
  AMOUNTS = [-38_700, -51_600, -12_900, -25_800].freeze

  def perform
    accounts.each do |account|
      vendor = account.vendor
      next if vendor.blank?
      next if vendor.paid_to.present?

      make_transaction account, vendor
    end
  end

  private

  def make_transaction(account, vendor)
    OpenbillTransaction.create!(
      from_account: source_account,
      amount: -account.amount,
      to_account: vendor.common_billing_account,
      key: "#{vendor.id}-compensation",
      details: 'Компенсация бесплатного периода.',
      meta: {
        compensation: 'free'.freeze
      }
    )

    notify vendor
  rescue StandardError => e
    puts "#{e}: #{account.id} #{vendor.host}"
  end

  def notify(vendor)
    vendor.owners.each do |member|
      OperatorMailer.some_mail(member.operator.id, vendor.id, SUBJECT).deliver! 1 if member.email.present?
    end
  end

  def source_account
    @source_account ||= OpenbillAccount.find Billing::GIFT_ACCOUNT_ID
  end

  def accounts
    OpenbillAccount.where('amount_cents < 0')
  end
end
