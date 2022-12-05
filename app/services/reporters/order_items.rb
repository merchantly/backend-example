class Reporters::OrderItems < Reporters::SalesBase
  include MoneyRails::ActionViewExtension
  include MoneyHelper
  include EcrHelper

  def headers
    [
      I18n.t('operator.reports.items_table_headers.datetime'),
      I18n.t('operator.reports.items_table_headers.order_id'),
      I18n.t('operator.reports.items_table_headers.total_sales', currency: vendor.default_currency),
      I18n.t('operator.reports.items_table_headers.total_vat', currency: vendor.default_currency),
      I18n.t('operator.reports.items_table_headers.item_name'),
      I18n.t('operator.reports.items_table_headers.item_id'),
      I18n.t('operator.reports.items_table_headers.item_price', currency: vendor.default_currency),
      I18n.t('operator.reports.items_table_headers.item_vat', currency: vendor.default_currency),
      I18n.t('operator.reports.items_table_headers.quantity'),
      I18n.t('operator.reports.items_table_headers.tid'),
      I18n.t('operator.reports.items_table_headers.payment_method')
    ].freeze
  end

  def ordered_headers
    {
      I18n.t('operator.reports.items_table_headers.datetime') => :created_at,
      I18n.t('operator.reports.items_table_headers.payment_method') => :payment
    }
  end

  class Report
    include Virtus.model

    attribute :headers
    attribute :ordered_headers
    attribute :rows
    attribute :paginate_items

    def to_csv
      CSV.generate do |csv|
        csv << headers

        rows.each do |row|
          csv << row
        end
      end
    end
  end

  def perform
    Report.new(headers: headers, ordered_headers: ordered_headers, rows: rows, paginate_items: order_items)
  end

  delegate :to_csv, to: :perform

  private

  def order_items
    s = super

    case filter.order.try(:to_sym)
    when ReportsFilter::CREATED_AT_ORDER
      s.order(created_at: (filter.permitted_order_direction || :desc))
    when ReportsFilter::PAYMENT_ORDER
      payment_key = filter.permitted_order_payment_key || VendorPaymentKeys::KEYS.first

      s.joins(:payment_type)
        .order(
          Arel.sql("CASE WHEN vendor_payments.payment_key = '#{payment_key}' THEN '0' ELSE vendor_payments.payment_key END, created_at DESC")
        )
    else
      s.order(created_at: :desc)
    end
  end

  def rows
    order_items.map do |oi|
      [
        I18n.l(oi.order.created_at, format: '%d/%m/%Y %H:%M'),
        "##{oi.order_id}",
        ecr_humanized_money_with_symbol(oi.order.total_price),
        ecr_humanized_money_with_symbol(oi.order.total_vat),
        oi.title,
        oi.good.try(:nomenclature).try(:barcode),
        ecr_humanized_money_with_symbol(oi.price),
        ecr_humanized_money_with_symbol(oi.vat_amount),
        oi.quantity,
        oi.order.tid,
        oi.payment_type.title
      ]
    end
  end
end
