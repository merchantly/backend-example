# TODO Отказаться и использовать массове декорирование
class Billing::AccountTransactionsFetcher
  DEFAULT_ORDER_COLUMN = :created_at

  def initialize(vendor, billing_account, order_column: :created_at, order_direction: :asc)
    @vendor = vendor
    @transactions = []
    @billing_account = billing_account
    @order_column = order_column
    @order_direction = order_direction
  end

  def fetch
    raw_transactions.each do |t|
      if t.to_account_id == Billing::SYSTEM_ACCOUNTS[:sms]
        transactions.push VendorTransactionSMS.new vendor, t
      else
        transactions.push VendorTransaction.new vendor, t
      end
    end
    transactions
  end

  private

  attr_reader :vendor, :transactions, :order_column, :order_direction, :billing_account

  def raw_transactions
    scope = billing_account.all_transactions

    scope = scope.order(order_column.to_sym)
    if order_direction != 'asc'
      scope = scope.reverse_order
    end
    scope
  end
end
