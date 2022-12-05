module VendorVkontakte
  extend ActiveSupport::Concern

  included do
    validates :vk_group_id, numericality: { greater_than: 0, allow_nil: true }
  end

  def vk_client
    auth = authentications.by_provider(:vkontakte).first

    raise 'Нет авторизации через vkontakte' unless auth

    auth.vk_client
  end

  def has_vkontakte?
    authentications.by_provider(:vkontakte).any?
  end

  def vkontakte_auth
    @vkontakte_auth ||= authentications.by_provider(:vkontakte).first
  end
end
