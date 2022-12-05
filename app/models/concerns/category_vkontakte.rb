module CategoryVkontakte
  extend ActiveSupport::Concern

  included do
    scope :vk_never_synced, -> { where vk_album_id: nil }
    scope :vk_out_of_sync,  -> { where 'vk_album_id is not null and vk_synced_at <= updated_at' }
    scope :vk_synced,       -> { where 'vk_album_id is not null and vk_synced_at > updated_at' }
  end
end
