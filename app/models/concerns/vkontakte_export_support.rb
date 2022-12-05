module VkontakteExportSupport
  extend ActiveSupport::Concern
  include NotyFlashHelper

  START_VK_EXPORT_FLAG = 'start_export'.freeze

  included do
    helper_method :vkontakte_groups
  end

  def update
    current_vendor.update! vendor_permitted_params

    if params[:submit] == START_VK_EXPORT_FLAG
      VendorJobVkontakte.create! vendor: current_vendor
      redirect_back fallback_location: operator_integration_vkontakte_path, flash: { FLASH_SUCCESS => I18n.t('flashes.vk.will_be_exported') }
    else
      redirect_to update_success_url
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: operator_integration_vkontakte_path, flash: { FLASH_ERROR => e.message }
  end

  private

  def vkontakte_groups
    return {} unless current_vendor.has_vkontakte?

    @vkontakte_groups ||= get_vkontakte_groups params[:force]
  end

  def get_vkontakte_groups(force = false)
    key = "vkontakte:#{current_vendor.vkontakte_auth.uid}:groups"
    Rails.cache.fetch key, force: force do
      Vkontakte::Resources::Groups
        .new(client: current_vendor.vkontakte_auth.vk_client)
        .index
    end
  end
end
