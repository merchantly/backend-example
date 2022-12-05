class GoodUpdateFromSpreadsheet
  include Virtus.model

  attribute :attrs
  attribute :vendor, Vendor
  attribute :root_product, Product
  attribute :row_index, Integer
  attribute :spreadsheet, GoogleSpreadsheet

  GoodError = Class.new StandardError

  NOMENCLATURE_ATTRS = %i[barcode quantity purchase_price vat].freeze
  IMAGE_ATTRS = [:image_link].freeze
  PRODUCT_EXCEPT_ATTRS = NOMENCLATURE_ATTRS + IMAGE_ATTRS + [:item_title].freeze
  PRODUCT_ITEM_EXCEPT_ATTRS = NOMENCLATURE_ATTRS + IMAGE_ATTRS + %i[title category description].freeze

  def perform
    good = find_or_build_good

    good.with_lock do
      good.restore if good.archived?
      update_good good
      update_nomenclature good
      update_quantity good
      add_image good
    end

    good
  end

  private

  def update_good(good)
    attrs.except(*except_attrs(good)).each do |key, value|
      if category_key?(key)
        category_ids = build_category_ids value
        good.category_ids = category_ids
      elsif translate_key?(key)
        key = :title if key == :item_title

        vendor.available_locales.each do |locale|
          # if blank, take other value
          locale_value = value[locale].presence || value.values.find(&:present?)

          good.send "custom_#{key}_#{locale}=", locale_value
        end
      else
        good.send "#{key}=", value
      end
    end

    good.save!
  end

  def build_category_ids(tr_categories)
    categories = []

    tr_categories.each do |locale, value|
      category_names = value.split(',').map(&:strip)

      category_names.each_with_index do |name, index|
        parts = name.split('/')

        parts.reverse!

        past_category = nil
        current_category = categories[index]

        parts.each do |part|
          if current_category.present?
            current_category.update_attribute "custom_title_#{locale}", part
          else
            current_category = vendor.categories.by_name(part).first || create_category(part)

            if past_category.present?
              past_category.update parent: current_category
            else
              categories << current_category
            end
          end

          past_category = current_category
          current_category = current_category.parent
        end
      end
    end

    categories.map(&:id)
  end

  def create_category(name)
    # set all locals
    vendor.categories.create! custom_title_translations: vendor.available_locales.index_with { name }
  end

  def update_nomenclature(good)
    return unless IntegrationModules.enable?(:ecr)

    if attrs[:barcode].blank?
      good.destroy_ecr_nomenclature!
    else
      good.create_ecr_nomenclature!

      good.nomenclature.update! barcode: attrs[:barcode] if good.nomenclature.barcode != attrs[:barcode]
      good.nomenclature.update! vat: attrs[:vat].to_i if attrs[:vat].present?
    end
  end

  def update_quantity(good)
    return if attrs[:quantity].blank?

    quantity = attrs[:quantity].to_f

    if IntegrationModules.enable?(:ecr) && good.nomenclature.present?
      return unless quantity.positive?

      form = Ecr::WarehouseMovementForm::Receipt.new(
        quantity: quantity,
        vendor: vendor,
        nomenclature_id: good.nomenclature.id,
        warehouse_id: vendor.default_warehouse.id,
        purchase_price: attrs[:purchase_price]
      )

      Ecr::WarehouseMovementRegistrar.receipt(form)
    else
      good.update! quantity: quantity
    end
  end

  def add_image(good)
    return if attrs[:image_link].blank?

    product = good.is_a?(Product) ? good : good.product

    product.add_image_by_url attrs[:image_link]
  rescue StandardError => e
    Bugsnag.notify e
  end

  def find_or_build_good
    if good_is_product_item?
      raise GoodError, I18n.t('errors.import_from_spreadsheet.empty_parent_product') if root_product.blank?

      product_item = find_product_item

      return product_item if product_item.present?

      root_product.items.build
    else
      product = find_product

      return product if product.present?

      vendor.products.build
    end
  end

  def find_product_item
    if attrs[:barcode].present?
      root_product.items.joins(:nomenclature).where(ecr_nomenclatures: { barcode: attrs[:barcode] }).first
    elsif attrs[:article].present?
      root_product.items.find_by(article: attrs[:article])
    elsif attrs[:title].present?
      root_product.items.by_titles(attrs[:item_title].values).first
    end
  end

  def find_product
    if attrs[:barcode].present?
      vendor.products.joins(:nomenclature).where(ecr_nomenclatures: { barcode: attrs[:barcode] }).first
    elsif attrs[:article].present?
      vendor.products.find_by(article: attrs[:article])
    elsif attrs[:title].present?
      vendor.products.by_titles(attrs[:title].values).first
    else
      raise GoodError, I18n.t('errors.import_from_spreadsheet.empty_product_line')
    end
  end

  def translate_key?(key)
    TableColumns::TR_COLUMNS_LIST.include?(key)
  end

  def category_key?(key)
    key == :category
  end

  def good_is_product_item?
    return false if attrs[:item_title].blank?

    attrs[:item_title].values.map(&:present?).reduce :|
  end

  def except_attrs(good)
    case good
    when Product
      PRODUCT_EXCEPT_ATTRS
    when ProductItem
      PRODUCT_ITEM_EXCEPT_ATTRS
    else
      raise "Unknown class: #{good}"
    end
  end
end
