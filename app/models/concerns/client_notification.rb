module ClientNotification
  extend ActiveSupport::Concern

  included do
    before_update do
      self.require_notification = will_save_change_to_client_category_id?
    end

    after_commit if: :require_notification do
      ClientNotificationService.new(self).client_category_changed
    end
  end

  private

  attr_accessor :require_notification
end
