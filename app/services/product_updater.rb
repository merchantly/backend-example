class ProductUpdater
  def initialize(vendor:, params: {}, product: nil, image: nil, barcode: nil, nomenclature_quantity: nil, nomenclature_purchase_price: nil)
    @vendor = vendor
    @params = params
    @product = product
    @image = image
    @barcode = barcode
    @nomenclature_quantity = nomenclature_quantity
    @nomenclature_purchase_price = nomenclature_purchase_price
  end

  def perform
    updated_product = Product.transaction do
      updated_product = ProductBuilder.new(vendor: vendor, params: params, product: product).build
      updated_product.save!

      update_image! updated_product if image.present?
      update_barcode! updated_product if barcode.present?
      update_nomeclature_quantity! updated_product if nomenclature_quantity.present? && IntegrationModules.enable?(:ecr)
      updated_product
    end

    # Сброс кеша nginx и thumbor
    product_image.rename! if product_image.present?

    updated_product
  end

  private

  attr_reader :vendor, :params, :product, :image, :barcode, :nomenclature_quantity, :nomenclature_purchase_price, :product_image

  def update_image!(updated_product)
    @product_image = ProductImage.create! vendor: vendor, product: updated_product, image: image
    updated_product.update! image_ids: ([product_image.id] + updated_product.image_ids)
  end

  def update_barcode!(updated_product)
    nomenclature = updated_product.nomenclature
    nomenclature.update! barcode: barcode if nomenclature.present?
  end

  def update_nomeclature_quantity!(updated_product)
    if nomenclature_quantity.to_f.positive?
      form = Ecr::WarehouseMovementForm::Receipt.new(
        quantity: nomenclature_quantity,
        vendor: vendor,
        nomenclature_id: updated_product.nomenclature.id,
        warehouse_id: vendor.default_warehouse.id,
        purchase_price: nomenclature_purchase_price
      )

      Ecr::WarehouseMovementRegistrar.receipt(form)
    elsif nomenclature_quantity.to_f.negative?
      form = Ecr::WarehouseMovementForm::Expense.new(
        quantity: -nomenclature_quantity,
        vendor: vendor,
        nomenclature_id: updated_product.nomenclature.id,
        warehouse_id: vendor.default_warehouse.id
      )

      Ecr::WarehouseMovementRegistrar.expense(form)
    end
  end
end
