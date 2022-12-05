class MarketingDataExporter
  def all_payments
    return unless scope.exists?

    CSV.generate do |csv|
      csv << headers

      vendors.each do |vendor|
        csv << vendor_row(vendor)
      end
    end
  end

  def departed_customers
    return unless scope.exists?

    CSV.generate do |csv|
      dates.map do |date|
        vendors = scope.where('extract(month from date) = ? and extract(year from date) = ?', date.month, date.year)
                    .select { |i| i.vendor.invoices.paid.with_tariff.order(:date).last == i }
                    .map { |i| [i.vendor.id, i.vendor.invoices.paid.with_tariff.count] }.sort_by(&:second).map { |v| v.join('-') }

        csv << ([I18n.l(date + 1.month, format: '%B %Y')] + vendors)
      end
    end
  end

  def incoming_customers
    return unless scope.exists?

    CSV.generate do |csv|
      dates.map do |date|
        vendor_ids = scope.where('extract(month from date) = ? and extract(year from date) = ?', date.month, date.year)
                    .select { |i| i.vendor.invoices.paid.with_tariff.order(:date).first == i }
                    .map { |i| [i.vendor.id, i.amount.to_f, i.vendor.public_url] }.sort_by(&:second).map { |v| v.join('-') }

        csv << ([I18n.l(date, format: '%B %Y')] + vendor_ids)
      end
    end
  end

  private

  def vendor_row(vendor)
    arr = [vendor.id, vendor.public_url]

    dates.each do |date|
      invoice = vendor.invoices.paid.with_tariff.where('extract(month from date) = ? and extract(year from date) = ?', date.month, date.year).first

      arr << (invoice.present? ? invoice.amount.to_f : 0)
    end

    arr
  end

  def headers
    %w[ID Домен] + month_names
  end

  def month_names
    dates.map { |d| I18n.l(d, format: '%B %Y') }
  end

  def dates
    @dates ||= build_dates
  end

  def build_dates
    count_months = ((current_time.year * 12) + current_time.month) - ((first_date.year * 12) + first_date.month)

    (0..count_months).map do |i|
      first_date + i.months
    end
  end

  def first_date
    scope.order(:date).first.date
  end

  def vendors
    scope.map(&:vendor).sort_by(&:id).uniq
  end

  def scope
    OpenbillInvoice.paid.with_tariff
  end

  def current_time
    @current_time ||= Time.zone.now
  end
end
