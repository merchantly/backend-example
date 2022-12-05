class Reporters::WarehouseTransactions
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper
  include MoneyRails::ActionViewExtension
  include Operator::Ecr::WarehouseMovementsHelper
  include MoneyHelper
  include EcrHelper
  include QuantityHelper

  def headers
    [
      I18n.t('operator.reports.transactions_table_headers.datetime'),
      I18n.t('operator.reports.transactions_table_headers.type'),
      I18n.t('operator.reports.transactions_table_headers.details'),
      I18n.t('operator.reports.transactions_table_headers.cost'),
      I18n.t('operator.reports.transactions_table_headers.quantity')
    ]
  end

  class Report
    include Virtus.model

    attribute :headers
    attribute :rows
    attribute :paginate_items
    attribute :ordered_headers

    def to_csv
      sanitizer = Rails::Html::Sanitizer.full_sanitizer.new

      CSV.generate do |csv|
        csv << headers

        rows.each do |row|
          csv << row.map { |el| sanitizer.sanitize el }
        end
      end
    end
  end

  def initialize(vendor, filter, page = nil, per = nil)
    @vendor = vendor
    @filter = filter
    @per = per
    @page = page
  end

  def perform
    Report.new(
      headers: headers,
      ordered_headers: {},
      rows: rows,
      paginate_items: transactions
    )
  end

  delegate :to_csv, to: :perform

  private

  attr_reader :vendor, :filter, :per, :page

  def rows
    transactions.map do |wt|
      [
        I18n.l(wt.created_at, format: '%d/%m/%Y %H:%M'),
        ecr_warehouse_movement_type(wt),
        ecr_warehouse_movement_details(wt),
        (ecr_humanized_money_with_symbol(wt.purchase_price) if wt.purchase_price_cents.present?),
        humanized_quantity_with_unit(wt.quantity, wt.quantity_unit)
      ]
    end
  end

  def transactions
    scope = vendor.warehouse_movements

    if filter.present?
      scope = scope.where('ecr_warehouse_movements.created_at >= ? ', filter.from_date) if filter.from_date.present?
      scope = scope.where('ecr_warehouse_movements.created_at < ?', filter.till_date) if filter.till_date.present?
    end

    scope = scope.page(page).per(per) if per.present?

    scope.order(created_at: :desc)
  end
end
