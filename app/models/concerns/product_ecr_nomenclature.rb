module ProductEcrNomenclature
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
        if nomenclature.present? && nomenclature.products_and_items_empty?(except: self)
          if alive? && nomenclature.archived?
            nomenclature.restore!
          elsif archived? && nomenclature.alive?
            nomenclature.archive!
          end
        end
      end
    end
  end

  def ecr_nomenclature
    nomenclature
  end

  def create_ecr_nomenclature!
    return if is_a?(ProductUnion) || nomenclature.present?

    product_nomenclature = create_nomenclature! quantity_unit: quantity_unit, title: title, vendor: vendor
    update_column :nomenclature_id, product_nomenclature.id
  end

  def destroy_ecr_nomenclature!
    if nomenclature.present? && nomenclature.movements_empty? && nomenclature.products_and_items_empty?(except: self)
      nomenclature.destroy!
    end
  end

  private

  def create_first_receipt_to_warehouse!
    return if self[:quantity].to_f.zero?

    form = Ecr::WarehouseMovementForm::Receipt.new(quantity: self[:quantity], vendor: vendor, nomenclature_id: nomenclature.id, warehouse_id: vendor.default_warehouse.id, purchase_price: first_purchase_price)

    Ecr::WarehouseMovementRegistrar.receipt(form)
  end
end
