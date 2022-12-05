module ProductUnionImages
  def public_image_ids
    if image_ids.any?
      image_ids
    else
      parts_image_ids
    end
  end

  def parts_image_ids
    products.alive.map(&:image_ids).flatten.uniq
  end

  def parts_images
    ProductImage.find parts_image_ids
  end
end
