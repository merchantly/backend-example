module Vkontakte
  module Resources
    # https://vk.com/dev/photos
    class Albums < Base
      # @param params[Hash]
      def index(params = {})
        @albums ||= try { client.photos.getAlbums(params) }.map { |data| parse_data data }
      end

      # @param id - album id
      def get(id)
        index album_ids: id
      end

      # @param Vkontakte::Entities::LocalAlbum
      # @return Vkontakte::Entitie::Album - созданный альбом
      def create(album_local)
        @albums = nil
        parse_data(try { client.photos.createAlbum album_local.to_hash })
      end

      def update(album_update)
        try { client.photos.editAlbum album_update.to_hash }
      end

      private

      def entity_class
        ::Vkontakte::Entities::Album
      end
    end
  end
end
