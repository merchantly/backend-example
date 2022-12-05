module VendorPriceKinds
  extend ActiveSupport::Concern

  included do
    has_many :price_kinds, dependent: :destroy
    belongs_to :default_price_kind, class_name: 'PriceKind'
    belongs_to :sale_price_kind, class_name: 'PriceKind'

    after_create :create_price_kinds
  end

  def custom_price_kinds
    price_kinds.where.not(id: [default_price_kind_id, sale_price_kind_id])
  end

  private

  def create_price_kinds
    default = price_kinds.create! title_translations: HstoreTranslate.translations(:default, %i[titles price_kinds]), vendor_id: id
    sale = price_kinds.create! title_translations: HstoreTranslate.translations(:sale, %i[titles price_kinds]), vendor_id: id
    update_columns default_price_kind_id: default.id, sale_price_kind_id: sale.id
  end
end
