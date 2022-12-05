class ProductsGenerator
  def self.perform(vendor, category, count)
    count.times.each do |i|
      new_product = Product.new
      new_product.vendor = vendor
      new_product.title = "example-product-#{i}"
      new_product.image_ids = []
      new_product.data = {}
      new_product.category_ids = [category.id]
      new_product.uuid = nil
      new_product.category_id = category.id
      new_product.price = Money.new(10_000, vendor.default_currency)
      new_product.sale_price = Money.new(9000, vendor.default_currency)
      new_product.is_published = true
      new_product.quantity = 10
      new_product.save!

      if IntegrationModules.enable?(:ecr)
        new_product.nomenclature.update vat: 5, purchase_price: Money.new(10_000, vendor.default_currency), quantity: 10
      end

      new_product.update_ordering!
    end
  end
end
