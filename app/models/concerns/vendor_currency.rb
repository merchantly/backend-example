module VendorCurrency
  extend ActiveSupport::Concern

  CURRENCIES = Settings::Currencies.all.map(&:iso_code)

  included do
    extend Enumerize
    after_save :update_currencies!, if: :saved_change_to_currency_iso_code?
    after_commit :vendor_reindex, on: :update, if: ->(_model) { previous_changes.key?(:currency_iso_code) && previous_changes['currency_iso_code'].first.present? }

    before_validation on: :create do
      self.currency_iso_code ||= Money.default_currency.iso_code
    end
    validates :currency_iso_code, inclusion: { in: CURRENCIES }
    enumerize :available_currencies, in: CURRENCIES, multiple: true
  end

  def default_currency
    Money::Currency.find currency_iso_code || Money.default_currency
  end

  def zero_money
    Money.new 0, default_currency
  end

  def all_currencies
    currencies = available_currencies << currency_iso_code
    Money::Currency.select { |c| currencies.include? c.iso_code }
  end

  def currency_available?(iso_code)
    currency = Money::Currency.find iso_code
    all_currencies.include? currency
  end

  private

  def update_currencies!
    code = default_currency.iso_code
    update_columns minimal_price_currency: code, total_orders_price_currency: code, total_success_orders_price_currency: code
    product_prices.update_all price_currency: code
    vendor_deliveries.update_all price_currency: code, free_delivery_threshold_currency: code

    order_items.update_all price_currency: code
  end

  def vendor_reindex
    VendorReindexWorker.perform_async id
  end
end
