module ProductVkontakte
  extend ActiveSupport::Concern

  included do
    scope :vk_never_synced, -> { where vk_photo_id: nil }
    scope :vk_out_of_sync,  -> { where 'vk_photo_id is not null and vk_synced_at <= updated_at' }
    scope :vk_synced,       -> { where 'vk_photo_id is not null and vk_synced_at > updated_at' }
  end
end
