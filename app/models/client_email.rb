class ClientEmail < ApplicationRecord
  belongs_to :client
  belongs_to :vendor

  scope :unconfirmed, -> { where confirmed: false }
  validates :email, email: true, uniqueness: { scope: :client_id }

  before_save do
    self.vendor ||= client.vendor
  end

  def to_s
    email
  end

  def marked_for_destruction?
    !confirmed? && super
  end

  def confirm!
    update_columns confirmed: true, confirmed_at: Time.zone.now
  end
end
