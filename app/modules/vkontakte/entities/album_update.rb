module Vkontakte
  module Entities
    # [{"album_id"=>39792669,
    # "owner_id"=>"-12882460",
    # "title"=>"альбом как альбом",
    # "description"=>"личные фото",
    # "privacy_view"=>{"type"=>"all"},
    # "privacy_comment"=>{"type"=>"all"}}],
    # "upload_by_admins_only"=>1,
    # "comments_disabled"=>0

    class AlbumUpdate < Base
      attribute :album_id, Integer
      attribute :owner_id, String
      attribute :title, String
    end
  end
end
