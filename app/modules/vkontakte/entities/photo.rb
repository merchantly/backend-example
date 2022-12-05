module Vkontakte
  module Entities
    # http://vk.com/dev/photos.getById

    class Photo < Base
      attribute :id, Integer
      attribute :album_id, Integer
      attribute :owner_id, Integer

      attribute :photo_75, String
      attribute :photo_130, String
      attribute :photo_604, String

      attribute :text, String
      attribute :date, Integer

      attribute :post_id, Integer
    end
  end
end
