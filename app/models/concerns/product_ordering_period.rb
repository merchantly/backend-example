module ProductOrderingPeriod
  extend ActiveSupport::Concern

  MAX_DELAY = 1.minute

  included do
    validate :validate_ordering_period
  end

  private

  def validate_ordering_period
    return if ordering_start_at.blank? || ordering_end_at.blank?

    errors.add :ordering_period, I18n.t('errors.product.ordering_period') if ordering_start_at > ordering_end_at
    errors.add :ordering_period, I18n.t('errors.product.beginning_of_ordering_period', time_now: Time.zone.now) if will_save_change_to_ordering_start_at? && (ordering_start_at < Time.zone.now - MAX_DELAY)
  end
end
