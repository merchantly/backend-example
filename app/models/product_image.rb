class ProductImage < ApplicationRecord
  include Authority::Abilities
  include ImageWithGeometry
  include ProductImageDigest

  self.authorizer_name = 'ProductImageAuthorizer'

  has_one :moysklad_object, as: :reference

  belongs_to :product
  belongs_to :vendor

  mount_uploader :image, ImageUploader

  scope :ordered, -> { order 'is_main desc, position desc' }
  scope :alive, -> { all }

  delegate :url, :adjusted_url, :rotate!, to: :image
  delegate :title, to: :product

  before_save { self.vendor ||= product.try(:vendor) }
  after_destroy :remove_from_product

  def remote_image_url=(url)
    self.saved_remote_image_url = url
    super url
  end

  def uid
    digest.presence || id
  end

  def rename!
    image.rename!
    reload
  end

  # У картинки может не быть product_id если она загружена
  # при добавлении еще не сохраненного товара

  def productize!(product)
    if product_id.present?
      unless product_id == product.id
        raise "Wrong product_id in product_image #{id} -> #{product_id}<>#{product.id}"
      end
    else
      update_column :product_id, product.id
    end
  end

  private

  def remove_from_product
    product.try :remove_image_id, id
  end
end
