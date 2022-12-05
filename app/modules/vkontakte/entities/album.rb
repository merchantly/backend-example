module Vkontakte
  module Entities
    # [{"id"=>39792669,
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

    class Album < Base
      attribute :id, Integer
      attribute :thumb_id, Integer
      attribute :owner_id, Integer
      attribute :title, String
      attribute :description, String
      attribute :created, Integer
      attribute :updated, Integer

      attribute :size, Integer
      attribute :privacy, Integer
      attribute :privacy_view, Hash
      attribute :privacy_comment, Hash
    end
  end
end
