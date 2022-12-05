module ProductItemEcrNomenclature
  extend ActiveSupport::Concern

  included do
    belongs_to :nomenclature, class_name: 'Ecr::Nomenclature'

    delegate :purchase_price, to: :ecr_nomenclature, allow_nil: true

    monetize :first_purchase_price_cents,
             as: :first_purchase_price,
             with_model_currency: :first_purchase_price_currency,
             allow_nil: true,
             numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

    if IntegrationModules.enable?(:ecr)
      validates :first_purchase_price_cents, presence: true, on: :create, if: -> { self[:quantity].to_f.positive? }

      after_create do
        create_ecr_nomenclature!
        create_first_receipt_to_warehouse!
      end

      before_destroy do
        destroy_ecr_nomenclature!
      end

      before_save if: :will_save_change_to_archived_at? do
        if alive?
          create_ecr_nomenclature!
        else
          destroy_ecr_nomenclature!
        end
      end
    end
  end

  def ecr_nomenclature
    nomenclature
  end

  def create_ecr_nomenclature!
    return if nomenclature.present?

    product_item_nomenclature = create_nomenclature!(quantity_unit: product.quantity_unit, title: long_title, vendor: vendor)
    update_column :nomenclature_id, product_item_nomenclature.id

    product.destroy_ecr_nomenclature!
  end

  def destroy_ecr_nomenclature!
    nomenclature.destroy! if nomenclature.present? && nomenclature.movements_empty? && nomenclature.products_and_items_empty?(except: self)

    product.create_ecr_nomenclature! if product.present? && product.ecr_nomenclature.blank?

    product.create_ecr_nomenclature!
  end

  private

  def create_first_receipt_to_warehouse!
    return if self[:quantity].to_f.zero?

    form = Ecr::WarehouseMovementForm::Receipt.new(quantity: self[:quantity], vendor: vendor, nomenclature_id: nomenclature.id, warehouse_id: vendor.default_warehouse.id, purchase_price: first_purchase_price)

    Ecr::WarehouseMovementRegistrar.receipt(form)
  end
end
