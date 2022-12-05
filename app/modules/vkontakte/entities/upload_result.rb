module Vkontakte
  module Entities
    # {"server"=>621829,
    # "photos_list"=>
    # "[{\"photo\":\"1fde5fcb0f:w\",\"sizes\":[[\"s\",\"621829460\",\"5b2d\",\"58Mj2mcmEcc\",75,75],[\"m\",\"621829460\",\"5b2e\",\"QAHBIUHN6XE\",130,130],[\"x\",\"621829460\",\"5b2f\",\"HlmGyGjpatA\",604,604],[\"y\",\"621829460\",\"5b30\",\"YPE-43Hd5WQ\",807,807],[\"z\",\"621829460\",\"5b31\",\"raS8hcJNPpU\",1024,1024],[\"w\",\"621829460\",\"5b32\",\"5Ih52TtSm8M\",1500,1500],[\"o\",\"621829460\",\"5b33\",\"IHRcGJnzOo0\",130,130],[\"p\",\"621829460\",\"5b34\",\"cTUpVeTEhFU\",200,200],[\"q\",\"621829460\",\"5b35\",\"RgkT8vs7tEc\",320,320],[\"r\",\"621829460\",\"5b36\",\"lBRIZml6z_I\",510,510]],\"kid\":\"8ff7019d0bda416b9942d049682d8243\"}]",
    # "aid"=>208594172,
    # "hash"=>"4b0a19c67e1839cc87643768a66eeac6",
    # "gid"=>83086022}

    class UploadResult < Base
      attribute :gid,  Integer
      attribute :hash, String
      attribute :aid,  Integer

      attribute :server, Integer

      attribute :photos_list, String
    end
  end
end
