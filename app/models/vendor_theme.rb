class VendorTheme < ApplicationRecord
  extend Enumerize
  PRODUCT_COLUMNS_RANGE = (1..4).freeze
  PRODUCT_ROWS_RANGE = (1..100).freeze
  STYLE_FORMATS = %w[SCSS SASS].freeze
  FONTS = %i[helvetica ptserif ptsans verdana gotham courier lora].freeze
  FONT_SIZES = %i[sm md lg].freeze

  REACT_ENGINE = :react
  LIQUID_ENGINE = :liquid
  ENGINES = [REACT_ENGINE, LIQUID_ENGINE].freeze

  OTHER_PRODUCTS_COUNT = 8

  # TODO
  # перенести сюда logo
  #

  mount_uploader :page_bg, VendorBackgroundUploader

  belongs_to :vendor, touch: true

  before_validation do
    # Default values:
    #
    # https://github.com/BrandyMint/merchantly/wiki/%5BНастройки-дизайна%5D-Значения-по-умолчанию
    self.theme_template_key ||= Theme.all.first.key
    self.custom_style_format ||= STYLE_FORMATS.first
    self.page_bg_color ||= '#ffffff'
    self.feed_bg_color ||= '#ffffff'
    self.font_color ||= '#000000'
    self.feed_transparency ||= 0
    self.font_family ||= 'helvetica'
    self.font_size ||= 'md'
    self.mainpage_product_columns ||= 3
    self.category_product_columns ||= 3
  end

  # У wannabe товаров 4 в ряд. У остальных 3. Диапазон 2-4. Так?
  enumerize :product_image_position, in: %w[above aside], default: 'aside'

  enumerize :engine, in: ENGINES

  validates :custom_body_class, length: { maximum: 255 }, allow_blank: true
  validates :mainpage_product_columns, inclusion: PRODUCT_COLUMNS_RANGE
  validates :mainpage_product_rows,    inclusion: PRODUCT_ROWS_RANGE
  validates :category_product_columns, inclusion: PRODUCT_COLUMNS_RANGE
  validates :category_product_rows,    inclusion: PRODUCT_ROWS_RANGE

  validates :theme_template_key, presence: true, inclusion: Theme.all.map(&:key)

  validates :custom_style_format, presence: true, inclusion: VendorTheme::STYLE_FORMATS
  validates :custom_style, style: { format_field: :custom_style_format }
  validates :page_bg_color, css_hex_color: true
  validates :font_color,    css_hex_color: true
  validates :feed_bg_color, css_hex_color: true
  validates :history_products_count, numericality: { greater_than: 0, less_than: HistoryProducts::MAX_HISTORY_PRODUCTS_COUNT, allow_nil: true }

  delegate :has_auto_menu, to: :vendor

  after_initialize do
    self.mainpage_product_columns ||= 3
    self.category_product_columns ||= 3
  end

  before_save :trim_w1_widget_ptenabled

  MAPPING = {
    pageBgFile: :page_bg,
    pageBgColor: :page_bg_color,
    fontFamily: :font_family,
    fontColor: :font_color,
    fontSize: :font_size,
    feedBgColor: :feed_bg_color,
    feedTransparency: :feed_transparency,
    productPagePhoto: :product_image_position,
    activeElementsColor: :active_elements_color,
    mainPageProductsInRow: :mainpage_product_columns,
    mainPageRows: :mainpage_product_rows,
    mainPageFilter: :mainpage_filter_visible,
    categoryPageProductsInRow: :category_product_columns,
    categoryPageRows: :category_product_rows,
    categoryPageFilter: :category_filter_visible,
    mainPageSlider: :slider_visible,
    mainPageBanner: :banner_visible,
    w1Widget: :w1_widget_visible,
    showSimilarProducts: :show_similar_products,
    showCartButtonInList: :show_cart_button_in_list,
    showQuantityInList: :show_quantity_in_list,
    mainPageRandom: :is_welcome_random
  }.freeze

  def has_auto_menu=(value)
    vendor.update_attribute :has_auto_menu, value
  end

  def update_design_settings!(params)
    params = params.symbolize_keys
    transaction do
      attrs = {}
      params.each_pair { |k, v| attrs[MAPPING[k]] = v if MAPPING.key? k }
      attrs[:remove_page_bg] = true if params[:pageBgFileRemove]
      update! attrs if attrs.present?

      vendor.update! logo: params[:logoFile] if params[:logoFile].present?
      vendor.update! remove_logo: params[:logoFileRemove] if params[:logoFileRemove]
    end

    self
  end

  def welcome_products_per_page
    mainpage_product_columns * mainpage_product_rows
  end

  def similar_products_count
    category_product_columns
  end

  def other_products_count
    OTHER_PRODUCTS_COUNT
  end

  def theme_template
    Theme.find theme_template_key
  end

  def body_class
    custom_body_class || theme_template.body_class
  end

  def render_style
    return '' if custom_style.blank?

    case style_syntax
    when :sass, :scss
      style_engine.render
    else
      custom_style
    end
  end

  def custom_style_url
    vendor_css.url + "?style_version=#{style_version}"
  end

  private

  def vendor_css
    @vendor_css ||= VendorCss.new(vendor: vendor)
  end

  def trim_w1_widget_ptenabled
    self.w1_widget_ptenabled = w1_widget_ptenabled.to_s.gsub(/\s+/, '')
  end

  def style_version
    # DOTO style_updated_at
    updated_at.to_i
  end

  def style_syntax
    if custom_style_format == 'SASS'
      :sass
    else
      :scss
    end
  end

  def style_engine
    SassC::Engine.new(custom_style, syntax: style_syntax)
  end
end
