class ImagesImporter
  ImageTitleEmpty = Class.new StandardError

  def initialize(images:, vendor:)
    @images = images
    @vendor = vendor
  end

  def perform
    imported_images_count = 0
    errors = []

    images.each do |image|
        import_product_image image
        imported_images_count += 1
    rescue StandardError => e
        errors << e
    end

    ImagesImporterResult.new(imported_images_count: imported_images_count, errors: errors)
  end

  private

  attr_reader :images, :vendor

  def import_product_image(image)
    title = File.basename(image.original_filename, '.*')

    raise ImageTitleEmpty if title.blank?

    # photo (1), photo (2), photo (3)
    title = title.gsub(/\(\d+?\)$/, '')

    products = vendor.products.by_title(title)
    products = [vendor.products.create!(title: title)] if products.blank?

    products.each do |product|
      product.restore if product.archived?
      pi = ProductImage.create! image: image, vendor_id: vendor.id, product: product
      product.update_column :image_ids, product.image_ids + [pi.id]
    end
  end
end
