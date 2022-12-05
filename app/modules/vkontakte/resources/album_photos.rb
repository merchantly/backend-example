require 'net/http/post/multipart'

module Vkontakte
  module Resources
    # https://vk.com/dev/photos
    # https://vk.com/dev/upload_files?f=Загрузка%20фотографий%20в%20альбом%20пользователя
    class AlbumPhotos < Base
      attribute :album_id, Integer, required: true
      attribute :group_id, Integer, required: true
      attribute :files, Array, required: true
      attribute :caption, String

      def create
        raise 'Файлов для загрузки должно быть от 1 до 5-и' unless (1..5).cover? files.count

        upload_raw = upload upload_uri
        upload_result = Vkontakte::Entities::UploadResult.new upload_raw
        save upload_result, upload_raw

        # {"server": '1', "photos_list": '2,3,4', "album_id": '5', "hash": '12345abcde'}
      end

      def update(photo_id)
        try do
          client.photos.edit(
            owner_id: "-#{group_id}",
            photo_id: photo_id,
            caption: caption
          )
        end
      end

      # @param id - album id
      # def get id
      # index album_ids: id
      # end

      private

      def save(upload_result, upload_raw)
        res = try do
          client.photos.save(
            album_id: album_id,
            group_id: group_id,
            server: upload_result.server,
            photos_list: upload_result.photos_list,
            hash: upload_result.hash,
            caption: caption
          )
        end

        res.map do |photo|
          Vkontakte::Entities::CreatedPhoto.new photo
        end
      rescue StandardError => e
        Bugsnag.notify e, upload: upload_raw
        raise e
      end

      def upload(uri)
        http = Net::HTTP.new(uri.host, uri.port)

        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        req = Net::HTTP::Post::Multipart.new uri, params
        res = http.request(req)

        JSON.parse res.body
      end

      def params
        @params ||= build_params
      end

      def build_params
        params = {}
        idx = 0
        files.each_with_index do |file, _index|
          data = file_data file
          params["file#{idx += 1}"] = data if data.present?
        end
        params
      end

      def file_data(file)
        UploadIO.new(
          File.new(file),
          MIME::Types.of(file).first.content_type,
          File.basename(file)
        )
      rescue StandardError => e
        Bugsnag.notify e, metaData: { file: file, album_id: album_id, group_id: group_id }
        raise e
      end

      def upload_uri
        URI.parse get_upload_server['upload_url']
      end

      def get_upload_server
        @get_upload_server ||= try do
          client.photos.getUploadServer album_id: album_id, group_id: group_id
        end
      end

      # {"upload_url"=>
      # "http://cs621828.vk.com/upload.php?act=do_add&mid=12882460&aid=208072332&gid=83086022&hash=e1b560e582169c1042f1993d35eb5554&rhash=f70f46d52b020bfa3ba30e96777b25e4&swfupload=1&api=1",
      # "aid"=>208072332,
      # "mid"=>12882460}

      def entity_class
        ::Vkontakte::Entities::Photo
      end
    end
  end
end
