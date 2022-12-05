module TableColumns
  extend ActiveSupport::Concern

  COLUMNS_LIST = %i[skip price sale_price quantity new_property image_link].freeze
  COMMON_COLUMNS_LIST = [:article].freeze
  ECR_COLUMNS_LIST = %i[barcode purchase_price vat].freeze
  TR_COLUMNS_LIST = %i[item_title title description category].freeze # have different translations
  TR_SEPARATOR = ':'.freeze
  PRICE_COLUMNS = %i[price sale_price purchase_price].freeze

  def columns
    @columns ||= build_columns_list.index_by { |column| I18n.t(column, scope: %i[google_spreadsheet columns], locale: locale) }
  end

  def tr_columns
    @tr_columns ||= TR_COLUMNS_LIST.index_by { |column| I18n.t(column, scope: %i[google_spreadsheet columns], locale: locale) }
  end

  def column_types
    types = columns.dup

    vendor.available_locales.each do |locale|
      tr_columns.each do |key, value|
        separator = TR_SEPARATOR

        types["#{key}#{separator}#{locale}"] = "#{value}#{separator}#{locale}"
      end
    end

    vendor.properties.alive.each do |p|
      types[I18n.t('google_spreadsheet.property_title', title: p.title, locale: locale)] = "property:#{p.id}"
    end

    types
  end

  def find_column_definitions(headers)
    raise EmptyTableError if total_rows_count.zero?

    headers.map do |title|
      if tr_column?(title)
        field, locale = title.split(TR_SEPARATOR)

        locale = I18n.locale if locale.blank?

        "#{tr_columns[field]}#{TR_SEPARATOR}#{locale}"
      elsif key?(title)
        if Settings::Features.product_properties
          property = vendor.properties.by_title(title).first

          if property.present?
            "property:#{property.id}"
          else
            :new_property
          end
        end
      else
        columns[title]
      end
    end
  end

  class EmptyTableError < StandardError; end

  private

  def build_columns_list
    list = IntegrationModules.enable?(:ecr) ? ECR_COLUMNS_LIST : COMMON_COLUMNS_LIST

    list + COLUMNS_LIST
  end

  def tr_column?(column)
    tr_columns.keys.map { |k| column.start_with?(k) }.any?
  end

  def key?(title)
    columns.keys.exclude?(title)
  end
end
