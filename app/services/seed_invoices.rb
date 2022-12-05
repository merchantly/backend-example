# Создаем магазинам счета на основе списка
# из ./db/shops.csv
#
class SeedInvoices
  def perform
    rows.map do |row|
      vendor = Vendor.find_by(host: URI.parse(row[0]).host) || raise("Не найден магазин #{row[0]}")
      amount = row[1].to_money
      create_invoice vendor, amount rescue ActiveRecord::RecordInvalid
      vendor
    end
  end

  private

  def create_invoice(vendor, amount)
    OpenbillInvoice.create!(
      destination_account: vendor.common_billing_account,
      number: "#{vendor.id}-FZ54",
      date: Date.current,
      title: "Поддержка платежным шлюзом требований закона 54-ФЗ для магазина #{vendor}",
      amount: amount,
      service_id: Billing::ADDITIONAL_WORKS_SERVICE_ID,
      meta: {
        service: 'fz54'
      }
    )
  end

  def rows
    CSV.read('./db/shops.csv')
  end
end
