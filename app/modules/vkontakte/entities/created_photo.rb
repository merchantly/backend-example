module Vkontakte
  module Entities
    # http://vk.com/dev/photos.getById
    #=> [{"pid"=>349588339,
    # "id"=>"photo12882460_349588339",
    # "aid"=>208594172,
    # "owner_id"=>-83086022,
    # "user_id"=>12882460,
    # "src"=>"http://cs621829.vk.me/v621829460/5b4c/xaUQj0St4AU.jpg",
    # "src_big"=>"http://cs621829.vk.me/v621829460/5b4d/d8p5nDZlCtA.jpg",
    # "src_small"=>"http://cs621829.vk.me/v621829460/5b4b/0hq_0aC7PuQ.jpg",
    # "src_xbig"=>"http://cs621829.vk.me/v621829460/5b4e/JlwMeQC4sGY.jpg",
    # "src_xxbig"=>"http://cs621829.vk.me/v621829460/5b4f/ERRFXqLfttE.jpg",
    # "src_xxxbig"=>"http://cs621829.vk.me/v621829460/5b50/vpGYYITIGpI.jpg",
    # "width"=>1500,
    # "height"=>1500,
    # "text"=>"Анклет Стрелка с цирконами золоченый",
    # "created"=>1419859166}]

    class CreatedPhoto < Base
      attribute :pid, Integer
      attribute :id,  String
      attribute :aid, Integer
      attribute :owner_id, Integer
      attribute :user_id, Integer

      attribute :src, String
      attribute :src_big, String
      attribute :src_small, String
      attribute :src_xbig, String
      attribute :src_xxbig, String
      attribute :src_xxxbig, String

      attribute :width, Integer
      attribute :height, Integer

      attribute :text, String

      attribute :created, Integer
    end
  end
end
