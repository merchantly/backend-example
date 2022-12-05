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

    class Group < Base
      attribute :id, Integer
      attribute :name, String
      attribute :screen_name, String

      attribute :is_closed, Integer
      attribute :is_admin, Integer
      attribute :is_member, Integer
      attribute :deactivated, String

      attribute :type, String # group, page, event

      attribute :photo_50, String
      attribute :photo_100, String
      attribute :photo_200, String

      attribute :city, String
      attribute :country, String

      # attribute :place, Place

      attribute :created, Integer
      attribute :updated, Integer

      attribute :description, String

      attribute :site, String

      attribute :main_album_id, Integer
    end
  end
end
