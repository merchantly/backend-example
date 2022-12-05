module Vkontakte
  module Entities
    # [{"aid"=>39792669,
    # "thumb_id"=>"115436833",
    # "owner_id"=>"12882460",
    # "title"=>"альбом как альбом",
    # "description"=>"личные фото",
    # "created"=>"1218436307",
    # "updated"=>"1218436380",
    # "size"=>1,
    # "privacy"=>0,
    # "privacy_view"=>{"type"=>"all"},
    # "privacy_comment"=>{"type"=>"all"}}]

    class LocalAlbum
      include Virtus.model

      attribute :title, String, required: true
      attribute :group_id, Integer

      attribute :description, String

      attribute :privacy, Integer, default: 0
      attribute :comment_privacy, Integer, default: 0
      attribute :upload_by_admins_only, Integer, default: 1
      attribute :comments_disabled, Integer, default: 0
    end
  end
end
