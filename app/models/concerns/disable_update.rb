module DisableUpdate
  extend ActiveSupport::Concern

  included do
    before_update :disable_update
  end

  private

  def disable_update
    raise 'You can not update invite, only create' if persisted?
  end
end
