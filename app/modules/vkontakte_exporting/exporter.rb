module VkontakteExporting
  class Exporter
    include Virtus.model
    attribute :vendor,    Vendor, required: true
    attribute :group_id,  Integer, required: true
    attribute :inspector, JobInspector, required: true

    def perform
      self.synced_at = Time.zone.now
      vendor.update_column :vk_synced_at, synced_at
      inspector.total = total_categories_count + total_products_count
      export_categories
      export_products
      inspector.finish "Выгружено #{total_products_count} товаров в #{total_categories_count} категорий"

      # Ошибка ловится выше
    end

    private

    attr_accessor :synced_at

    def total_categories_count
      vendor.categories.alive.count
    end

    def total_products_count
      vendor.products.alive.active.count
    end

    def export_categories
      inspector.details = 'Обновляю категории'

      vendor.categories.alive.vk_never_synced.find_each do |category|
        create_album category
        inspector.increment
      end

      vendor.categories.alive.vk_out_of_sync.find_each do |category|
        update_album category
        inspector.increment
      end

      inspector.current = total_categories_count
    end

    def export_products
      vendor.categories.alive.vk_synced.find_each do |category|
        create_or_update_products category
      end
    end

    def create_or_update_products(category)
      inspector.details = 'Обновляю товары'

      category.products.published.vk_out_of_sync.find_each do |p|
        update_product album_id: category.vk_album_id, product: p
      end

      category.products.published.vk_never_synced.find_each do |p|
        next if p.image.blank?

        create_product album_id: category.vk_album_id, product: p
      end
    end

    def create_product(album_id:, product:)
      res = album_photos album_id: album_id, product: product
      photo = res.create.first
      product.update_columns vk_photo_id: photo.id, vk_synced_at: synced_at
    end

    def update_product(album_id:, product:)
      res = album_photos album_id: album_id, product: product
      res.update product.vk_photo_id.split('_')[1].to_i
      product.update_columns vk_synced_at: synced_at
    end

    def album_photos(album_id:, product:)
      Vkontakte::Resources::AlbumPhotos.new(
        client: vendor.vk_client,
        album_id: album_id,
        group_id: group_id,
        files: [product.image.image.url],
        caption: [product.title, product.price.format, product.public_url].join("\n")
      )
    end

    def create_album(category)
      la = Vkontakte::Entities::LocalAlbum.new title: category.name, group_id: group_id
      result_album = Vkontakte::Resources::Albums.new(client: vendor.vk_client).create la
      category.update_columns vk_album_id: result_album.id, vk_synced_at: synced_at
    end

    def update_album(category)
      album = Vkontakte::Entities::AlbumUpdate.new album_id: category.vk_album_id, owner_id: "-#{group_id}", title: category.name
      Vkontakte::Resources::Albums.new(client: vendor.vk_client).update album
      category.update_columns vk_synced_at: synced_at
    end
  end
end
