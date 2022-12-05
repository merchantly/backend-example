class ImportFromSpreadsheet
  include Virtus.model strict: true

  attribute :vendor, Vendor
  attribute :rows, Array
  attribute :column_definitions, Array
  attribute :skip_rows, Integer, default: 1
  attribute :spreadsheet, GoogleSpreadsheet

  SKIP_KEY = 'skip'.freeze

  def perform
    imported_products_count = 0

    columns = build_columns

    @current_row_num = 0

    root_product = nil

    rows.each_with_index do |row, row_index|
      @current_row = row
      @current_row_num = row_index + 1

      next if row_index < skip_rows

      attrs = build_attributes(columns, row).symbolize_keys

      good = import_good attrs, root_product

      if good.present?
        root_product = good if good.is_a?(Product)

        imported_products_count += 1
      end

      yield row_index + 1, imported_products_count if block_given?
    end

    {
      imported_products_count: imported_products_count,
      messages: messages
    }
  end

  def messages
    @messages ||= []
  end

  private

  attr_reader :current_row_num, :current_row

  def build_columns
    column_definitions.each_with_index.map do |key, index|
      value = rows[0][index].to_s
      column_key = value.to_s.blank? ? SKIP_KEY : key

      if column_key.to_s == 'new_property'
        property_key = "property:#{value.parameterize}"

        property = vendor.properties.find_by(key: property_key) || PropertyString.create!(vendor: vendor, title: value, custom_title: value, key: property_key)
        column_key = "property:#{property.id}"
      end

      column_key
    end
  end

  def build_attributes(columns, row)
    attrs = Hashie::Mash.new data: {}

    columns.each_with_index do |key, index|
      next if key == SKIP_KEY

      set_attribute attrs, key, row[index], (index + 1)
    end

    attrs
  end

  def set_attribute(attrs, key, value, current_col_num)
    key = key.to_s unless key.is_a?(String)

    case key_type(key)
    when :property_key
      property_id = key.split(':').last
      if value.present?
        property = get_property property_id
        if property.is_a? PropertyDictionary
          attrs[:data][property_id] = property.dictionary.entities.find_or_create_by_title(value).id
        else
          attrs[:data][property_id] = value
        end
      end
    when :translation_key
      key, locale = key.split(TableColumns::TR_SEPARATOR)

      locale = I18n.locale if locale.blank?

      raise I18n.t('errors.import_from_spreadsheet.not_allowed_locale', locale: locale) unless vendor.available_locales.include?(locale)

      attrs[key] ||= {}
      attrs[key][locale] = value
    when :price_key
      numeric_value = spreadsheet.numeric_value(current_row_num, current_col_num)

      money_value = numeric_value.try(:to_money, vendor.default_currency)
      money_value = nil if money_value.to_f.zero? && key == 'sale_price'

      attrs[key] = money_value
    when :simple_key
      attrs[key] = value
    else
      raise "Unknown #{key}"
    end
  end

  def get_property(property_id)
    vendor.properties.find property_id
  end

  def import_good(attrs, root_product)
    GoodUpdateFromSpreadsheet.new(vendor: vendor, attrs: attrs, root_product: root_product).perform
  rescue GoodUpdateFromSpreadsheet::GoodError, ActiveRecord::RecordInvalid => e
    add_message e.message
    false
  rescue StandardError => e
    Bugsnag.notify e, metaData: { vendor_id: vendor.id, p: p }
    add_message e.message
    false
  end

  def add_message(message)
    messages << { row_num: current_row_num, row: current_row, message: message }
  end

  def key_type(key)
    if key.start_with? 'property:'
      :property_key
    elsif TableColumns::TR_COLUMNS_LIST.map { |f| key.start_with?(f.to_s) }.any?
      :translation_key
    elsif TableColumns::PRICE_COLUMNS.map(&:to_s).include?(key)
      :price_key
    else
      :simple_key
    end
  end
end
