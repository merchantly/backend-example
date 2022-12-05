module ProductImages
  extend ActiveSupport::Concern

  included do
    scope :by_image_id, ->(_image_id) { where '?=ANY(image_ids)' }

    # validate :validate_image_ids, if: :image_ids_changed?
    before_save :clear_image_ids, if: :will_save_change_to_image_ids?
    before_save :cache
    after_save :productize_images!, if: :saved_change_to_image_ids?
    after_create :productize_images!, if: :saved_change_to_image_ids?
    after_initialize { self.image_ids ||= [] if new_record? }
  end

  def add_image_by_url(image_url)
    pi = ProductImage.create! product: self, remote_image_url: image_url, vendor: vendor
    self.image_ids = image_ids + [pi.id]
    save
  end

  def card_images
    @card_images ||= (images + goods_images).uniq(&:uid)
  end

  def goods_images
    goods.map(&:images).flatten
  end

  def mandatory_images
    return card_images if card_images.any?

    [OpenStruct.new(url: ImageUploader.new.default_url, title: title)]
  end

  def image
    public_image || product_union.try(:public_image)
  end

  def public_image
    ProductImage.find_by id: public_image_ids.first if public_image_ids.any?
  end

  def public_image_ids
    image_ids
  end

  def editable_images
    vendor.product_images.find_with_order image_ids
  end

  # Так делаем image с готовым fallback
  def mandatory_index_image
    image || ProductImage.new(product: self)
  end

  # Индексируется
  def index_image_url
    image.try :url
  end

  def second_image
    images.second
  end

  def second_image_url
    second_image.try :url
  end

  def images_count
    image_ids.count
  end

  def images_url
    images.to_a.flatten.map(&:url)
  end

  def images
    dirty_images_load
  end

  def restore_images!
    update_columns image_ids: all_image_ids
  end

  def remove_image_id(image_id)
    ids = image_ids
    ids.delete image_id
    update_column :image_ids, ids
  end

  private

  def dirty_images_load
    if public_image_ids.empty?
      ProductImage.none
    else
      # Получаем именно так, чтобы сохранился порядок
      vendor.product_images.find_with_order public_image_ids
    end
  end

  def clear_image_ids
    self.image_ids = dirty_images_load.pluck(:id)
  end

  def validate_image_ids
    dirty_images_load
  rescue ActiveRecord::RecordNotFound
    errors.add :image_ids, I18n.t('errors.image.no_files')
  end

  def all_image_ids
    ((image_ids || []) + product_image_ids).compact.uniq
  end

  def image_ids_to_remove
    image_ids_was - image_ids
  end

  # выполнять нужно в конце сохранения
  # потому что именно тогда есть id у товара в случае
  # его создания
  def productize_images!
    vendor.product_images
          .where(id: image_ids, product_id: nil).update_all product_id: id
    if image_ids_to_remove.any?
      vendor.product_images
            .where(id: image_ids_to_remove).delete_all
    end
  end

  def cache
    self.cached_image_url = image.try :url
    self.cached_public_url = public_url
    self.cached_has_images = image_ids.present? if will_save_change_to_image_ids?
  end
end
