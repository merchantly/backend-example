module VendorQuantityUnits
  extend ActiveSupport::Concern

  PCS_KEY = :pcs
  KG_KEY = :kg
  DEFAULT_KEYS = [PCS_KEY, KG_KEY].freeze

  PCS_QUANTITY_UNIT = {
    key: PCS_KEY,
    unit_type: QuantityUnit::INDIVISIBLE_TYPE,
    title_translations: HstoreTranslate.translations(:title, %i[units pcs]),
    short_translations: HstoreTranslate.translations(:short, %i[units pcs])
  }.freeze

  KG_QUANTITY_UNIT = {
    key: KG_KEY,
    unit_type: QuantityUnit::DIVISIBLE_TYPE,
    title_translations: HstoreTranslate.translations(:title, %i[units kg]),
    short_translations: HstoreTranslate.translations(:short, %i[units kg])
  }.freeze

  DEFAULT_QUANTIY_UNITS = [
    PCS_QUANTITY_UNIT,
    KG_QUANTITY_UNIT
  ].freeze

  included do
    has_many :quantity_units

    after_create :create_default_quantity_units!
  end

  def default_pcs_quantity_unit
    @default_pcs_quantity_unit ||= quantity_units.find_by key: PCS_KEY
  end

  def default_kg_quantity_unit
    @default_kg_quantity_unit ||= quantity_units.find_by key: KG_KEY
  end

  def create_default_quantity_units!
    DEFAULT_QUANTIY_UNITS.each do |dqu|
      quantity_units.create_with(unit_type: dqu[:unit_type], title_translations: dqu[:title_translations], short_translations: dqu[:short_translations]).find_or_create_by!(key: dqu[:key])
    end
  end
end
